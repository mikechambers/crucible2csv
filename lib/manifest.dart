/*
 * Copyright 2019 Mike Chambers, Grant Skinner
 * Released under an MIT License
 * https://opensource.org/licenses/MIT
 */

import 'dart:io';
import 'dart:convert';
import "dart:async";

import 'medal.dart';
import 'weapon.dart';

import 'mode.dart';

import 'activity.dart';
import "weapon_type.dart";

class Manifest {

  String _manifestPath;
  Map _destinyAcitivtyInfo;
  Map _destinyEmblemInfo;
  Map _activityModeDefinitions;
  Map _medalDefinitions;
  Map _weaponDefinitions;
  String _version;

  get version => _version;

  String resourceBaseUrl;
  Manifest(String resourceBaseUrl){
    this.resourceBaseUrl = resourceBaseUrl;
  }

  bool _hasWeaponSupport = false;

  get hasWeaponSupport => _hasWeaponSupport;

  Future<String> init (String manifestPath) async {

    _manifestPath = manifestPath;

    File f = new File(_manifestPath);

    String content = await f.readAsString();
  
    Map json = jsonDecode(content) as Map<String, dynamic>;
    _destinyAcitivtyInfo = json["activityDefinitions"];
    _destinyEmblemInfo = json["emblemDefinitions"];
    _activityModeDefinitions = json["activityModeDefinitions"];
    _medalDefinitions = json["medalDefinitions"];
    _weaponDefinitions = json["weaponDefinitions"];

    if(_medalDefinitions == null) {
      print("MANIFEST : MEDAL DEFINITIONS NOT FOUND");
      _medalDefinitions = {};
    }

    if(_weaponDefinitions == null) {
      print("MANIFEST : WEAPON DEFINITIONS NOT FOUND");
      _weaponDefinitions = {};
      _hasWeaponSupport = false;
    } else {
      _hasWeaponSupport = true;
    }

    _version = json["version"];

    return _version;
  }


  Mode getMode(int id ) {
    Mode mode = Mode(
      id:id,
      name:_activityModeDefinitions[id.toString()]["name"],
      iconUrl: createResourceUrl(_activityModeDefinitions[id.toString()]["icon"])
    );

    if(mode.name == null) {
      print("MANIFEST: Mode not found : $id");
      return null;
    }

    return mode;
  }
  Medal getMedal(String id) {

    Map<String, dynamic> item = _medalDefinitions[id];

    if(item == null) {
      print("MANIFEST: Medal not found : $id");
      return null;
    }

    Medal medal = new Medal(
      id:id,
      description: item["description"],
      iconUrl: createResourceUrl(item["icon"]),
      name: item["name"],
      tierIndex: item["tierIndex"] 
    );

    return medal;
  }

  Weapon getWeapon(int id) {
    Map item = _weaponDefinitions[id.toString()];

    if(item == null) {
      print("MANIFEST: Weapon not found : $id");
      return null;
    }

    int type = WeaponType.fromName(item["type"]);

    Weapon weapon = new Weapon(
      id:id,
      name:item["name"],
      type:type
    );

    return weapon;
  }

  Activity getActivity(int id) {

    if(_destinyAcitivtyInfo == null) {
      print("You must call Manifest.init before using API.");
      return null;
    }

    var aMap = _destinyAcitivtyInfo[id.toString()];

    if(aMap == null) {
      print("Activity not found for id:$id");
      return null;
    }

    Activity a = Activity(
      id:id,
      mapName: aMap["name"],
      description: aMap["description"],
      iconUrl: createResourceUrl(aMap["icon"]),
      mapImageUrl: createResourceUrl(aMap["pgcrImage"])
    );

    return a;
  }

  String createResourceUrl(String path) {

    if(path == null) {
      return null;
    }
    
    return resourceBaseUrl + path;
  }

  int convertHashToId(int hash) {
    var id = hash;
    if ((id & (1 << (32 - 1))) != 0) {
        id = id - (1 << 32);
      }
    return id;
  }

}
