/*
 * Copyright 2019 Mike Chambers, Grant Skinner
 * Released under an MIT License
 * https://opensource.org/licenses/MIT
 */

class Platform {
  static const int xbox = 1;
  static const int psn = 2;
  static const int steam = 3;
  static const int battlenet = 4;

  static int fromLabel(String label) {
    int out;
    switch(label.toLowerCase()) {
      case "xbox":
        out = xbox;
        break;
      case "psn":
        out = psn;
        break;
      case "steam":
      case "pc":
        out = steam;
        break;
      case "battlenet":
        out = battlenet;
        break;
    }

    return out;
  }
}