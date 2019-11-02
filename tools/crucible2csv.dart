import 'dart:io' hide Platform;

import "../lib/platform.dart";

import "../lib/d2api.dart";
import "../lib/member_info_result.dart";
import "../lib/character.dart";
import "../lib/game_report.dart";
import "../lib/class_type.dart";
import "../lib/experience_type.dart";

import 'package:args/args.dart';

D2Api d2api;
String _seperator = ",";
String _lineSeperator = "\n";


void main(List<String> args) async {
  ArgParser parser = ArgParser();

  parser.addOption("apikey", abbr: "a");
  parser.addOption("platform", abbr: "p");
  parser.addOption("gamertag", abbr: "t");
  parser.addFlag("verbose"); //where to print extra info
  parser.addFlag("hunter"); //retrieve stats for hunter
  parser.addFlag("titan"); //retrieve stats for titan
  parser.addFlag("warlock"); //retrieve stats for warlock
  parser.addFlag("help"); //retrieve stats for warlock

  ArgResults results;
  try {
    results = parser.parse(args);
  } catch(e) {
    printUsage();
    exit(2);
  }

  if(results["help"]) {
    printUsage();
    exit(1);
  }

  String apikey = results["apikey"];
  String platformLabel = results["platform"];
  String gamertag = results["gamertag"];

  if (apikey == null || platformLabel == null || gamertag == null) {
    printUsage();
    exit(2);
  }

  int platformId = Platform.fromLabel(platformLabel);

  if(platformId == null) {
    printUsage();
    exit(2);
  }

  D2Api.debug = results["verbose"];
  d2api = D2Api(apikey: apikey);
  d2api.initManifest("manifest.json");

  MemberInfoResult member;
  try {
    member = await d2api.getMemberInfo(gamertag, platformId);
  } catch(e) {
    print("Error calling API. ${e.runtimeType}");
    exit(2);
  }

  //GameReport report = await d2api.getPostGameReport(1291189975, 2305843009264966984);
  //exit(1);

  List<Character> characters;

  try {
    characters = await d2api.getCharacters(member.memberId, platformId);
  } catch(e) {
    print("Error calling API. ${e.runtimeType}");
    exit(2);
  }

  List<GameReportContainer> reports = [];
  for(Character c in characters) {
    print("Loading games for ${ClassType.labelFromType(c.classType)}");
    List<int> ids = await d2api.getActivityIds(member.memberId, platformId, c.id);

    print("Found ${ids.length} games for ${ClassType.labelFromType(c.classType)}");

    int i = 1;
    for(int id in ids) {
      print("Loading ${i++} of ${ids.length}");
      GameReport report = await d2api.getPostGameReport(id, c.id);
      GameReportContainer container = GameReportContainer(classType: c.classType, report: report);
      reports.add(container);
    }
  }

  StringBuffer buffer = StringBuffer(createCSVHeader());
  buffer.write(_lineSeperator);

  for(GameReportContainer c in reports) {
    buffer.write(createCSVRow(c.report, c.classType));
    buffer.write(_lineSeperator);
  }

  String csv = buffer.toString();

  File f = new File("activity_history.csv");
  await f.writeAsString(csv);

  //GameReport report = await d2api.getPostGameReport(5049796295, 2305843009264966985);
  //List<int> ids = await d2api.getActivityIds(member.memberId, platformId, characters[1].id);


  //String csv = createCSVRow(report,  1);
  //print(csv);

  //pull all reports
  //sort
  //export to csv

  exit(1);

}

String createCSVHeader() {

  String out = "ID$_seperator"
        "CLASS$_seperator"
        "ABILITY_KILLS$_seperator"
        "ACTIVITY_DURATION$_seperator" 
        "ASSISTS$_seperator"
        "AVG_SCORE_PER_KILL$_seperator"
        "AVG_SCORE_PER_LIFE$_seperator"
        "COMPLETED$_seperator"
        "DEATHS$_seperator"
        "EFFICIENCY$_seperator"
        "EXPERIENCE_TYPE$_seperator"
        "GRENADE_KILLS$_seperator"
        "KILLS$_seperator"
        "KILLS_DEATHS_RATIO$_seperator"
        "KILLS_DEATHS_ASSISTS_RATIO$_seperator"
        "MAP_NAME$_seperator"
        //"${report.medalResults},"
        "MELEE_KILLS$_seperator"
        "MODE$_seperator"
        "OPPONENT_SCORE$_seperator"
        "OPPONENTS_DEFEATED$_seperator"
        "TIME$_seperator"
        "PRECISION_KILLS$_seperator"
        "RESULT$_seperator"
        "SCORE$_seperator"
        "SUPER_KILLS$_seperator"
        "TEAM_SCORE$_seperator"
        "TIME_PLAYED$_seperator"
        "MEDALS_EARNED$_seperator";
        //"${report.weaponResults}";
      return out;
}

String createCSVRow(GameReport report, int classType) {

  String classLabel = ClassType.labelFromType(classType);
  String experienceType = (report.experienceType == ExperienceType.valor)?"Valor":"Glory";
  String out = "${report.id}$_seperator"
        "$classLabel$_seperator"
        "${report.abilityKills}$_seperator"
        "${report.activityDurationSeconds}$_seperator" 
        "${report.assists}$_seperator"
        "${report.averageScorePerKill}$_seperator"
        "${report.averageScorePerLife}$_seperator"
        "${report.completed}$_seperator"
        "${report.deaths}$_seperator"
        "${report.efficiency}$_seperator"
        "$experienceType$_seperator"
        "${report.grenadeKills}$_seperator"
        "${report.kills}$_seperator"
        "${report.killsDeaths}$_seperator"
        "${report.killsDeathsAssists}$_seperator"
        "${report.mapName}$_seperator"
        //"${report.medalResults}$_seperator"
        "${report.meleeKills}$_seperator"
        "${report.modeName}$_seperator"
        "${report.opponentScore}$_seperator"
        "${report.opponentsDefeated}$_seperator"
        "${report.period}$_seperator"
        "${report.precisionKills}$_seperator"
        "${report.resultDisplay}$_seperator"
        "${report.score}$_seperator"
        "${report.superKills}$_seperator"
        "${report.teamScore}$_seperator"
        "${report.timePlayedSeconds}$_seperator"
        "${report.totalMedalsEarned}$_seperator";
        //"${report.weaponResults}";
      return out;
}

void printUsage() {
  print("dart crucible2csv.dart --apikey APIKEY --platform [xbox|psn|steam] --tag [GAMERTAG|STEAM64ID) [--verbose] [--hunter|--titan|--warlock] [--help]");
}

class GameReportContainer {
  int classType;
  GameReport report;

  GameReportContainer({this.classType, this.report});
}
