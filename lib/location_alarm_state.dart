import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:location_alarm/alarm.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProximityAlarmState extends GetxController {
  List<Alarm> alarms = <Alarm>[];

  // View Stuff
  ProximityAlarmViews currentView = ProximityAlarmViews.alarms;
  late PageController pageController;

  bool alarmIsCurrentlyTriggered = false;
  double alarmTimer = 0;

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
  var pas = Get.find<ProximityAlarmState>();
  for (var i = 0; i < pas.alarms.length; i++) {
    if (pas.alarms[i].id == id) {
      pas.alarms.removeAt(i);
      pas.update();
      saveAlarmsToSharedPreferences(); // update the storage
      return true;
    }
  }

  debugPrint('Error: no alarm $id found to be deleted.');
  return false;
}

Alarm? getAlarmById(String id) {
  var pas = Get.find<ProximityAlarmState>();

  for (var alarm in pas.alarms) {
    if (alarm.id == id) return alarm;
  }

  return null;
}

// pass your new alarm data here to update proxalarm state. The id field in newAlarmData is ignored. returns success.
bool updateAlarmById(String id, Alarm newAlarmData) {
  var pas = Get.find<ProximityAlarmState>();

  for (var alarm in pas.alarms) {
    if (alarm.id == id) {
      alarm.name     = newAlarmData.name;
      alarm.position = newAlarmData.position;
      alarm.radius   = newAlarmData.radius;
      alarm.color    = newAlarmData.color;
      alarm.active   = newAlarmData.active;
      pas.update();
      saveAlarmsToSharedPreferences();
      return true;
    }
  }

  return false;
}

void addAlarm(Alarm alarm) {
  var pas = Get.find<ProximityAlarmState>();

  pas.alarms.add(alarm);
  pas.update();
  saveAlarmsToSharedPreferences();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToSharedPreferences() async {
  var pas = Get.find<ProximityAlarmState>();
  var preferences = await SharedPreferences.getInstance();

  var alarmsJsonStrings = <String>[];
  for (var alarm in pas.alarms) {
    var alarmJson = alarmToJson(alarm);
    var alarmJsonString = jsonEncode(alarmJson);

    alarmsJsonStrings.add(alarmJsonString);
  }

  debugPrint('Saving alarms to shared preferences: $alarmsJsonStrings.');
  await preferences.setStringList(sharedPreferencesAlarmKey, alarmsJsonStrings);
}

Future<void> loadAlarmsFromSharedPreferences() async {
  var pas = Get.find<ProximityAlarmState>();

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

    pas.alarms.add(alarm);
  }

  pas.update();
}

Future<void> clearAlarmsFromSharedPreferences() async {
  var preferences = await SharedPreferences.getInstance();
  await preferences.remove(sharedPreferencesAlarmKey);
  debugPrint('Cleared alarms from shared preferences.');
}

void resetAlarmPlacementUIState() {
  var pas = Get.find<ProximityAlarmState>();
  pas.isPlacingAlarm = false;
  pas.alarmPlacementRadius = 100;
}

void changeAlarmSound({required bool newValue}) {
  var pas = Get.find<ProximityAlarmState>();
  pas.alarmSound = newValue;
  pas.update();
  saveSettingsToSharedPreferences();
}

void changeVibration({required bool newValue}) {
  var pas = Get.find<ProximityAlarmState>();
  pas.vibration = newValue;
  pas.update();
  saveSettingsToSharedPreferences();
}

void changeAlarmNotification({required bool newValue}) {
  var pas = Get.find<ProximityAlarmState>();
  pas.notification = newValue;
  pas.update();
  saveSettingsToSharedPreferences();
}

Future<void> saveSettingsToSharedPreferences() async {
  debugPrint('Saving settings to SharedPreferences');

  var pas = Get.find<ProximityAlarmState>();
  var preferences = await SharedPreferences.getInstance();

  await preferences.setBool(sharedPreferencesAlarmSoundKey, pas.alarmSound);
  await preferences.setBool(sharedPreferencesAlarmVibrationKey, pas.vibration);
  await preferences.setBool(sharedPreferencesAlarmNotificationKey, pas.notification);
}

Future<void> loadSettingsFromSharedPreferences() async {
  var pas = Get.find<ProximityAlarmState>();
  var preferences = await SharedPreferences.getInstance();

  pas.alarmSound = preferences.getBool(sharedPreferencesAlarmSoundKey) ?? true;
  pas.vibration = preferences.getBool(sharedPreferencesAlarmVibrationKey) ?? true;
  pas.notification = preferences.getBool(sharedPreferencesAlarmNotificationKey) ?? true;
  pas.update();
}

Future<void> navigateToAlarm(Alarm alarm) async {
  var pas = Get.find<ProximityAlarmState>();
  pas.currentView = ProximityAlarmViews.map;
  pas.update();
  await pas.pageController.animateToPage(pas.currentView.index, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
  pas.mapController.move(alarm.position, initialZoom);
}
