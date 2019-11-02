/*
 * Copyright 2019 Mike Chambers
 * Released under an MIT License
 * https://opensource.org/licenses/MIT
 */


import 'mode.dart';

class Activity {
  int id;

  Mode mode;
  String mapName;

  //(for PVP this is the location)
  String description;

  String iconUrl;
  String mapImageUrl;

  Activity({
    this.id,
    this.mapName, 
    this.description,
    this.iconUrl,
    this.mapImageUrl
  });
}
