import 'weapon.dart';

class WeaponResult {
  Weapon weapon;
  int kills;
  int precisionKills;
  double precisionKillsRatio;

  WeaponResult({
    this.weapon,
    this.kills,
    this.precisionKills,
    this.precisionKillsRatio
  });
}