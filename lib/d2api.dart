import 'dart:convert';
import 'dart:io' hide Platform;

import 'activity.dart';
import 'character.dart';
import 'errors/server_status_exception.dart';
import 'experience_type.dart';
import 'game_report.dart';
import 'game_result.dart';
import 'manifest.dart';
import 'medal.dart';
import 'medal_result.dart';
import 'member_info_result.dart';
import 'mode.dart';
import 'platform.dart';
import 'weapon.dart';
import 'weapon_result.dart';

class D2Api {
  String apikey;
  final String _apiBase = "https://www.bungie.net";
  final String _statsApiBase = "https://stats.bungie.net";
  final String _resourceBase = "https://www.bungie.net";

  static bool debug = false;

  final int _connectionTimeout = 10; //seconds

  Manifest _manifest;

  D2Api({this.apikey});

  Future<String> initManifest(String manifestPath) async {
    _manifest = Manifest(_resourceBase);
    String version = await _manifest.init(manifestPath);

    return version;
  }

  Future<MemberInfoResult> getMemberInfoFromSteam(String steamId) async {
    String path =
        "/Platform/User/GetMembershipFromHardLinkedCredential/12/${Uri.encodeComponent(steamId)}/";
    Map<String, dynamic> jData;

    try {
      jData = await _callApi(path, _apiBase);
    } catch (e) {
      throw e;
    }

    int id = int.parse(jData["Response"]["membershipId"]);

    if (id == null) {
      return null;
    }

    int platformId = jData["Response"]["membershipType"];

    String profilePath =
        "/Platform/Destiny2/$platformId/Profile/$id/?components=100";
    Map<String, dynamic> profile = await _callApi(profilePath, _apiBase);

    MemberInfoResult out;

    String label;

    try {
      label = profile["Response"]["profile"]["data"]["userInfo"]["displayName"];
    } catch (e) {
      print("getMemberInfoFromSteam : error parsing displayName name");
      return null;
    }

    out = MemberInfoResult(memberId: id, label: label, platformId: platformId);

    return out;
  }

  ///Looks up membership id based on gamertag and platform.
  ///Returns null if not found
  Future<MemberInfoResult> getMemberInfo(String name, int platformId) async {
    if (platformId == Platform.steam) {
      return getMemberInfoFromSteam(name);
    }

    String path =
        "/Platform/Destiny2/SearchDestinyPlayer/$platformId/${Uri.encodeComponent(name)}/";

    Map jData = await _callApi(path, _apiBase);

    List<dynamic> response = jData["Response"];

    name = name.toLowerCase();
    for (Map item in response) {
      String displayName = item["displayName"];
      if (displayName.toLowerCase() == name) {
        MemberInfoResult out = MemberInfoResult(
            memberId: int.parse(item["membershipId"]),
            label: displayName,
            platformId: platformId);

        return out;
      }
    }
    //user not found
    return null;
  }

  Future<GameReport> getPostGameReport(int activityId, int characterId) async {
    String path = "/Platform/Destiny2/Stats/PostGameCarnageReport/$activityId/";

    Map<String, dynamic> jData = await _callApi(path, _statsApiBase);

    Map<String, dynamic> response = jData["Response"];
    List<dynamic> entries = response["entries"];

    Map<String, dynamic> entry;
    for (Map<String, dynamic> e in entries) {
      if (int.parse(e["characterId"]) != characterId) {
        continue;
      }

      entry = e;
      break;
    }

    if (entry == null) {
      print("Character entry not found");
      return null;
    }

    GameReport result = GameReport();
    result.id = activityId;

    //TODO: add experience type

    int modeId = response["activityDetails"]["mode"];
    Mode mode = _manifest.getMode(modeId);
    result.modeName = mode.name;

    int referenceId = response["activityDetails"]["referenceId"];
    Activity a = _manifest.getActivity(referenceId);
    result.mapName = a.mapName;

    List<dynamic> modes = response["activityDetails"]["modes"];
    result.experienceType =
        (modes.contains(69)) ? ExperienceType.glory : ExperienceType.valor;

    result.period = DateTime.parse(response["period"]);

    Map<String, dynamic> extended;
    try {
      extended = entry["extended"]["values"];

      result.grenadeKills =
          int.parse(extended["weaponKillsGrenade"]["basic"]["displayValue"]);
      result.meleeKills =
          int.parse(extended["weaponKillsMelee"]["basic"]["displayValue"]);
      result.superKills =
          int.parse(extended["weaponKillsSuper"]["basic"]["displayValue"]);
      result.abilityKills =
          int.parse(extended["weaponKillsAbility"]["basic"]["displayValue"]);

      result.precisionKills =
          int.parse(extended["precisionKills"]["basic"]["displayValue"]);

      result.totalMedalsEarned =
          extended["allMedalsEarned"]["basic"]["value"].round();


    } catch (e) {
      print("PARSING ERROR: getExtendedPostGameReport : parsing extended : $e");
    }

    Map<String, dynamic> values;
    try {
      values = entry["values"];
      result.assists = values["assists"]["basic"]["value"].round();

      result.score = values["score"]["basic"]["value"].round();
      result.kills = values["kills"]["basic"]["value"].round();
      result.averageScorePerKill =
          values["averageScorePerKill"]["basic"]["value"];
      result.deaths = values["deaths"]["basic"]["value"].round();
      result.averageScorePerLife =
          values["averageScorePerLife"]["basic"]["value"];
      result.completed = values["completed"]["basic"]["value"] == 1.0;
      result.opponentsDefeated =
          values["opponentsDefeated"]["basic"]["value"].round();
      result.efficiency = values["efficiency"]["basic"]["value"];
      result.killsDeaths = values["killsDeathsRatio"]["basic"]["value"];
      result.killsDeathsAssists =
          values["killsDeathsAssists"]["basic"]["value"];
      result.activityDurationSeconds =
          values["activityDurationSeconds"]["basic"]["value"].round();
      //standing
      //team
      result.timePlayedSeconds =
          values["timePlayedSeconds"]["basic"]["value"].round();

      //todo: confirm this works with rumble
      result.teamScore = values["teamScore"]["basic"]["value"].round();

      int standing = values["standing"]["basic"]["value"].round();

      if (modes.contains(Mode.rumble)) {
        if (standing < 3) {
          result.result = GameResult.WIN;
          result.resultDisplay = "Victory";
        } else if (standing > 2 && standing < 6) {
          result.result = GameResult.LOSS;
          result.resultDisplay = "Defeat";
        } else {
          result.result = GameResult.NOT_VALID;
          result.resultDisplay = "Unknown";
        }
      } else {
        result.result = standing;
        switch (standing) {
          case GameResult.WIN:
            result.resultDisplay = "Victory";
            break;
          case GameResult.LOSS:
            result.resultDisplay = "Defeat";
            break;
          case GameResult.DRAW:
            result.resultDisplay = "Draw";
            break;
          default:
            result.result = GameResult.NOT_VALID;
            result.resultDisplay = "Unknown";
        }
      }
    } catch (e) {
      print("PARSING ERROR: getExtendedPostGameReport : parsing values : $e");
    }

    try {
      Map<String, dynamic> team = values["team"];

      if (team != null) {
        int teamId = values["team"]["basic"]["value"].round();

        List<dynamic> teams = response["teams"];

        //only list opponent score for modes with two teams. Otherwise, only list
        //team score
        if (teams.length == 2) {
          for (Map<String, dynamic> v in teams) {
            if (v["teamId"].round() == teamId) {
              continue;
            }

            result.opponentScore = v["score"]["basic"]["value"].round();
          }
        }
      } else {
        //rumble
        int lowest = 6;
        int opponentScore;
        for (Map<String, dynamic> e in entries) {
          if (int.parse(e["characterId"]) == characterId) {
            continue;
          }

          int s = e["standing"].round();

          if (s <= lowest) {
            lowest = s;
            opponentScore = e["score"]["basic"]["value"].round();
          }
        }

        //opponent score is top player, or if player is top, 2nd top player
        result.opponentScore = opponentScore;
      }
    } catch (e) {
      print("PARSING ERROR: getExtendedPostGameReport : parsing scores : $e");
    }

    List<MedalResult> medalResults = [];
    try {
      extended.forEach((key, value) {
        if (key.startsWith("medal") && !key.startsWith("medals")) {
  
          Medal m = _manifest.getMedal(key);

          //todo: what should we do if we cant find the medal / null
          MedalResult r = MedalResult(
              count: int.parse(value["basic"]["displayValue"]), medal: m);
          medalResults.add(r);
        }
      });

      medalResults.sort(_medalSort);
    } catch (e) {
      print("PARSING ERROR: getExtendedPostGameReport : parsing medals : $e");
    }
    result.medalResults = medalResults;

    List<WeaponResult> weaponResults = [];
    try {
      List<dynamic> weapons = entry["extended"]["weapons"];

      //weapons can be empty / null if no weapon kills
      if (weapons != null) {
        for (Map<String, dynamic> w in weapons) {
          Weapon weapon = _manifest.getWeapon(w["referenceId"]);
          WeaponResult r = WeaponResult(
              weapon: weapon,
              kills: int.parse(
                  w["values"]["uniqueWeaponKills"]["basic"]["displayValue"]),
              precisionKills: int.parse(w["values"]
                  ["uniqueWeaponPrecisionKills"]["basic"]["displayValue"]),
              precisionKillsRatio: w["values"]
                  ["uniqueWeaponKillsPrecisionKills"]["basic"]["value"]);
          weaponResults.add(r);
        }
      }
    } catch (e) {
      print("PARSING ERROR: getExtendedPostGameReport : parsing weapons : $e");
    }
    result.weaponResults = weaponResults;

    return result;
  }

  Future<List<int>> getActivityIds(
      int memberId, int platformId, int characterId,
      [int page = 0]) async {
    int mode = 5; //AllPVP
    int count = 250;
    String path =
        "/Platform/Destiny2/$platformId/Account/$memberId/Character/$characterId/Stats/Activities/?mode=$mode&count=$count&page=$page";

    Map<String, dynamic> jData;

    for (int i = 0; i < 5; i++) {
      try {
        jData = await _callApi(path, _apiBase);
        break;
      } catch (e) {
        //wait here
        print("getActivityIds failed");
        await Future.delayed(Duration(seconds: 2));
      }
    }

    if (jData == null) {
      return null;
    }

    List<dynamic> activities = jData["Response"]["activities"];

    List<int> out = [];
    for (Map<String, dynamic> a in activities) {
      int id = int.parse(a["activityDetails"]["instanceId"]);

      out.add(id);
    }

    if(debug) {
      print("$page : ${out.length}");
    }

    if (out.length == count) {
      List<int> tmp =
          await getActivityIds(memberId, platformId, characterId, ++page);

      if (tmp == null) {
        return null;
      }

      out.addAll(tmp);
    }

    return out;
  }

  Future<List<Character>> getCharacters(int memberId, int platformId) async {
    String path =
        "/Platform/Destiny2/$platformId/Profile/$memberId/?components=200";

    Map<String, dynamic> jData = await _callApi(path, _apiBase);

    Map<String, dynamic> data = jData["Response"]["characters"]["data"];

    List<Character> characters = [];
    data.forEach((k, v) {
      int id = int.parse(k);
      int classType = v["classType"];

      Character c = Character(id: id, classType: classType);
      characters.add(c);
    });

    return characters;
  }

  Future<Map<String, dynamic>> _callApi(String apiPath, String apiBase) async {
    String path = apiBase + apiPath;

    HttpClient client = HttpClient();
    client.connectionTimeout = new Duration(seconds: _connectionTimeout);

    Uri uri = Uri.parse(path);

    if (debug) {
      print(uri.toString());
    }

    HttpClientRequest request;

    try {
      request = await client.getUrl(uri);
    } catch (e) {
      if (e is SocketException) {
        //timeout
        throw e;
      } else {
        throw e;
      }
    }

    request.headers.set("X-API-Key", apikey);

    HttpClientResponse response;
    try {
      response = await request.close();
    } catch (e) {
      throw e;
    }

    StringBuffer buffer = new StringBuffer("");

    try {
      await for (String b in response.transform(utf8.decoder)) {
        buffer.write(b);
      }
    } catch (e) {
      throw e;
    }

    String body = buffer.toString();

    Map<String, dynamic> jData;
    try {
      jData = jsonDecode(body);
    } catch (e) {
      //couldnt parse json
      throw e;
    }

    if (response.statusCode != 200) {
      //"statusCode:${response.statusCode} : $body"
      throw ServerStatusException(message: body, code: response.statusCode);
    }

    return jData;
  }
}

int _medalSort(MedalResult a, MedalResult b) {
  if (a.medal.tierIndex > b.medal.tierIndex) {
    return -1;
  } else if (a.medal.tierIndex < b.medal.tierIndex) {
    return 1;
  } else {
    return 0;
  }
}
