import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProxalarmState extends GetxController {
  ProxalarmView currentView = ProxalarmView.alarms;
  List<Alarm> alarms = <Alarm>[
    createAlarm(name: 'London', position: London, radius: 1000),
    createAlarm(name: 'Dublin', position: Dublin, radius: 2000, color: Colors.blue),
    createAlarm(name: 'Toronto', position: Toronto, radius: 3000, color: Colors.lightGreen),
    createAlarm(name: 'Belfast', position: Belfast, radius: 1000, color: Colors.purple),
  ];
  MapController mapController = MapController();
}

final Uuid idGenerator = Uuid();

bool deleteAlarmById(String id) {
  var ps = Get.find<ProxalarmState>();
  for (int i = 0; i < ps.alarms.length; i++) {
    if (ps.alarms[i].id == id) {
      ps.alarms.removeAt(i);
      return true;
    }
  }

  return false;
}

Alarm? getAlarmById(String id) {
  var ps = Get.find<ProxalarmState>();

  for (var alarm in ps.alarms) {
    if (alarm.id == id) return alarm;
  }

  return null;
}

Future<void> saveAlarmsToSharedPreferences() async {
  var ps = Get.find<ProxalarmState>();
  var preferences = await SharedPreferences.getInstance();

  var alarmsJsonStrings = <String>[];
  for (var alarm in ps.alarms) {
    var alarmJson = alarmToJson(alarm);
    var alarmJsonString = jsonEncode(alarmJson);

    alarmsJsonStrings.add(alarmJsonString);
  }

  print('Saving alarms to shared preferences: ${alarmsJsonStrings.toString()}');
  await preferences.setStringList('alarms', alarmsJsonStrings);
}

Future<void> loadAlarmsFromSharedPreferences() async {
  var ps = Get.find<ProxalarmState>();
  ps.alarms.clear();

  var preferences = await SharedPreferences.getInstance();

  final alarmsJsonStrings = preferences.getStringList('alarms');
  if (alarmsJsonStrings == null) {
    print('Error: Unable to load alarms');
    return;
  }

  for (var alarmJsonString in alarmsJsonStrings) {
    var alarmJson = jsonDecode(alarmJsonString);
    var alarm = alarmFromJson(alarmJson);

    ps.alarms.add(alarm);
  }
}

Future<void> clearAlarmsFromSharedPreferences() async {
  var preferences = await SharedPreferences.getInstance();
  await preferences.remove('alarms');
  print('Cleared alarms from shared preferences');
}
