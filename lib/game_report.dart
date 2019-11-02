import 'medal_result.dart';
import 'weapon_result.dart';
import 'experience_type.dart';


class GameReport {


  String mapName;
  String modeName;
  ExperienceType experienceType;

  //*********** */


  int grenadeKills;
  int superKills;
  int meleeKills;
  int abilityKills;

  int precisionKills;

  int id;
  int result;
  String resultDisplay;
  DateTime period;

  double killsDeaths;
  double killsDeathsAssists;
  double efficiency;
  int kills;
  int opponentsDefeated;
  int assists;
  int deaths;
  bool completed = false;

  double averageScorePerKill;
  double averageScorePerLife;
  int activityDurationSeconds;
  int timePlayedSeconds;
  int score;
  int totalMedalsEarned;

  int teamScore;
  int opponentScore;

  List<MedalResult> medalResults;
  List<WeaponResult> weaponResults;
}