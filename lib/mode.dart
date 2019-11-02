/*
 * Copyright 2019 Mike Chambers
 * Released under an MIT License
 * https://opensource.org/licenses/MIT
 */

class Mode {
  static const none = 0;
  static const allpvp = 5;
  static const rumble = 48;
  static const allprivate = 32;

  int id;
  String iconUrl;
  String name;

  Mode({this.id, this.iconUrl, this.name});
}
