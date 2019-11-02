class WeaponType {
  
  static const unknown = -1;
  static const rocketLauncher = 0;
  static const sniperRifle = 1;
  static const grenadeLauncher = 2;
  static const handCanon = 3;
  static const sidearm = 4;
  static const fusionRifle = 5;
  static const autoRifle = 6;
  static const pulseRifle = 7;
  static const shotgun = 8;
  static const sword = 9;
  static const scoutRifle = 10;
  static const submachineGun = 11;
  static const linearFusionRifle = 12;
  static const traceRifle = 13;
  static const machineGun = 14;
  static const combatBow = 15;

  static int fromName(String name) {
    
    int out = -1;
    switch (name){
       case "Rocket Launcher":
        out = rocketLauncher;
        break;
      case "Sniper Rifle":
        out = sniperRifle;
        break;
      case "Grenade Launcher":
        out = grenadeLauncher;
        break;
      case "Hand Cannon":
        out = handCanon;
        break;
      case "Sidearm":
        out = sidearm;
        break;
      case "Fusion Rifle":
        out = fusionRifle;
        break;
      case "Auto Rifle":
        out = autoRifle;
        break;
      case "Pulse Rifle":
        out = pulseRifle;
        break;
      case  "Shotgun":
        out = shotgun;
        break;
      case "Sword":
        out = sword;
        break;
      case "Scout Rifle":
        out = scoutRifle;
        break;
      case "Submachine Gun":
        out = submachineGun;
        break;
      case  "Linear Fusion Rifle":
        out = linearFusionRifle;
        break;
      case "Trace Rifle":
        out = traceRifle;
        break;
      case "Machine Gun":
        out = machineGun;
        break;
      case "Combat Bow":
        out = combatBow;
        break;
    }

    return out;
  }
}