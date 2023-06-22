import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProxalarmState extends GetxController {
  List<Alarm> alarms = <Alarm>[];

  // View Stuff
  ProxalarmViews currentView = ProxalarmViews.alarms;
  late PageController pageController;

  bool alarmIsCurrentlyTriggered = false;

  // MapView stuff
  MapController mapController = MapController();
  bool isPlacingAlarm = false;
  double alarmPlacementRadius = 100;

  // Settings
  bool alarmSound = true;
  bool vibration = true;
  bool notification = true;

  @override
  void onInit() {
    pageController = PageController(initialPage: currentView.index);
    super.onInit();
  }
}

// This is used to produce unique ids. Only one instantiation is needed.
final Uuid idGenerator = Uuid();

bool deleteAlarmById(String id) {
  var ps = Get.find<ProxalarmState>();
  for (var i = 0; i < ps.alarms.length; i++) {
    if (ps.alarms[i].id == id) {
      ps.alarms.removeAt(i);
      ps.update();
      saveAlarmsToSharedPreferences(); // update the storage
      return true;
    }
  }

  debugPrint('Error: no alarm $id found to be deleted.');
  return false;
}

Alarm? getAlarmById(String id) {
  var ps = Get.find<ProxalarmState>();

  for (var alarm in ps.alarms) {
    if (alarm.id == id) return alarm;
  }

  return null;
}

// pass your new alarm data here to update proxalarm state. The id field in newAlarmData is ignored. returns success.
bool updateAlarmById(String id, Alarm newAlarmData) {
  var ps = Get.find<ProxalarmState>();

  for (var alarm in ps.alarms) {
    if (alarm.id == id) {
      alarm.name = newAlarmData.name;
      alarm.position = newAlarmData.position;
      alarm.radius = newAlarmData.radius;
      alarm.color = newAlarmData.color;
      alarm.active = newAlarmData.active;
      ps.update();
      saveAlarmsToSharedPreferences();
      return true;
    }
  }

  return false;
}

void addAlarm(Alarm alarm) {
  var ps = Get.find<ProxalarmState>();

  ps.alarms.add(alarm);
  ps.update();
  saveAlarmsToSharedPreferences();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToSharedPreferences() async {
  var ps = Get.find<ProxalarmState>();
  var preferences = await SharedPreferences.getInstance();

  var alarmsJsonStrings = <String>[];
  for (var alarm in ps.alarms) {
    var alarmJson = alarmToJson(alarm);
    var alarmJsonString = jsonEncode(alarmJson);

    alarmsJsonStrings.add(alarmJsonString);
  }

  debugPrint('Saving alarms to shared preferences: $alarmsJsonStrings.');
  await preferences.setStringList(sharedPreferencesAlarmKey, alarmsJsonStrings);
}

Future<void> loadAlarmsFromSharedPreferences() async {
  var ps = Get.find<ProxalarmState>();

  var preferences = await SharedPreferences.getInstance();

  final alarmsJsonStrings = preferences.getStringList(sharedPreferencesAlarmKey);
  if (alarmsJsonStrings == null) {
    debugPrint('Warning: No alarms found in shared preferences.');
    return;
  }

  for (var alarmJsonString in alarmsJsonStrings) {
    var alarmJson = jsonDecode(alarmJsonString);
    var alarm = alarmFromJson(alarmJson as Map<String, dynamic>);
    debugPrint(alarmJsonString);

    ps.alarms.add(alarm);
  }

  ps.update();
}

Future<void> clearAlarmsFromSharedPreferences() async {
  var preferences = await SharedPreferences.getInstance();
  await preferences.remove(sharedPreferencesAlarmKey);
  debugPrint('Cleared alarms from shared preferences.');
}

void resetAlarmPlacementUIState() {
  var ps = Get.find<ProxalarmState>();
  ps.isPlacingAlarm = false;
  ps.alarmPlacementRadius = 100;
}

void changeAlarmSound({required bool newValue}) {
  var ps = Get.find<ProxalarmState>();
  ps.alarmSound = newValue;
  ps.update();
  saveSettingsToSharedPreferences();
}

void changeVibration({required bool newValue}) {
  var ps = Get.find<ProxalarmState>();
  ps.vibration = newValue;
  ps.update();
  saveSettingsToSharedPreferences();
}

void changeAlarmNotification({required bool newValue}) {
  var ps = Get.find<ProxalarmState>();
  ps.notification = newValue;
  ps.update();
  saveSettingsToSharedPreferences();
}

Future<void> saveSettingsToSharedPreferences() async {
  debugPrint('Saving settings to SharedPreferences');

  var ps = Get.find<ProxalarmState>();
  var preferences = await SharedPreferences.getInstance();

  await preferences.setBool(sharedPreferencesAlarmSoundKey, ps.alarmSound);
  await preferences.setBool(sharedPreferencesAlarmVibrationKey, ps.vibration);
  await preferences.setBool(sharedPreferencesAlarmNotificationKey, ps.notification);
}

Future<void> loadSettingsFromSharedPreferences() async {
  var ps = Get.find<ProxalarmState>();
  var preferences = await SharedPreferences.getInstance();

  ps.alarmSound = preferences.getBool(sharedPreferencesAlarmSoundKey) ?? true;
  ps.vibration = preferences.getBool(sharedPreferencesAlarmVibrationKey) ?? true;
  ps.notification = preferences.getBool(sharedPreferencesAlarmNotificationKey) ?? true;
  ps.update();
}

Future<void> navigateToAlarm(Alarm alarm) async {
  var ps = Get.find<ProxalarmState>();
  ps.currentView = ProxalarmViews.map;
  ps.update();
  await ps.pageController.animateToPage(ps.currentView.index, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
  ps.mapController.move(alarm.position, initialZoom);
}
