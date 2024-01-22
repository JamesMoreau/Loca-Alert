import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
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
  bool showMarkersInsteadOfCircles = false;
  Alarm? closestAlarm;
  bool closestAlarmIsInView = false;
  LatLng centerOfMap = LatLng(0, 0);

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
  var las = Get.find<ProximityAlarmState>();
  for (var i = 0; i < las.alarms.length; i++) {
    if (las.alarms[i].id == id) {
      las.alarms.removeAt(i);
      las.update();
      saveAlarmsToSharedPreferences(); // update the storage
      return true;
    }
  }

  debugPrint('Error: no alarm $id found to be deleted.');
  return false;
}

Alarm? getAlarmById(String id) {
  var las = Get.find<ProximityAlarmState>();

  for (var alarm in las.alarms) {
    if (alarm.id == id) return alarm;
  }

  return null;
}

// pass your new alarm data here to update proxalarm state. The id field in newAlarmData is ignored. returns success.
bool updateAlarmById(String id, Alarm newAlarmData) {
  var las = Get.find<ProximityAlarmState>();

  for (var alarm in las.alarms) {
    if (alarm.id == id) {
      alarm.name = newAlarmData.name;
      alarm.position = newAlarmData.position;
      alarm.radius = newAlarmData.radius;
      alarm.color = newAlarmData.color;
      alarm.active = newAlarmData.active;
      las.update();
      saveAlarmsToSharedPreferences();
      return true;
    }
  }

  return false;
}

void addAlarm(Alarm alarm) {
  var las = Get.find<ProximityAlarmState>();

  las.alarms.add(alarm);
  las.update();
  saveAlarmsToSharedPreferences();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToSharedPreferences() async {
  var las = Get.find<ProximityAlarmState>();
  var preferences = await SharedPreferences.getInstance();

  var alarmsJsonStrings = <String>[];
  for (var alarm in las.alarms) {
    var alarmJson = alarmToJson(alarm);
    var alarmJsonString = jsonEncode(alarmJson);

    alarmsJsonStrings.add(alarmJsonString);
  }

  debugPrint('Saving alarms to shared preferences: $alarmsJsonStrings.');
  await preferences.setStringList(sharedPreferencesAlarmKey, alarmsJsonStrings);
}

Future<void> loadAlarmsFromSharedPreferences() async {
  var las = Get.find<ProximityAlarmState>();

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

    las.alarms.add(alarm);
  }

  las.update();
}

Future<void> clearAlarmsFromSharedPreferences() async {
  var preferences = await SharedPreferences.getInstance();
  await preferences.remove(sharedPreferencesAlarmKey);
  debugPrint('Cleared alarms from shared preferences.');
}

void resetAlarmPlacementUIState() {
  var las = Get.find<ProximityAlarmState>();
  las.isPlacingAlarm = false;
  las.alarmPlacementRadius = 100;
}

void changeAlarmSound({required bool newValue}) {
  var las = Get.find<ProximityAlarmState>();
  las.alarmSound = newValue;
  las.update();
  saveSettingsToSharedPreferences();
}

void changeVibration({required bool newValue}) {
  var las = Get.find<ProximityAlarmState>();
  las.vibration = newValue;
  las.update();
  saveSettingsToSharedPreferences();
}

void changeAlarmNotification({required bool newValue}) {
  var las = Get.find<ProximityAlarmState>();
  las.notification = newValue;
  las.update();
  saveSettingsToSharedPreferences();
}

Future<void> saveSettingsToSharedPreferences() async {
  debugPrint('Saving settings to SharedPreferences');

  var las = Get.find<ProximityAlarmState>();
  var preferences = await SharedPreferences.getInstance();

  await preferences.setBool(sharedPreferencesAlarmSoundKey, las.alarmSound);
  await preferences.setBool(sharedPreferencesAlarmVibrationKey, las.vibration);
  await preferences.setBool(sharedPreferencesAlarmNotificationKey, las.notification);
}

Future<void> loadSettingsFromSharedPreferences() async {
  var las = Get.find<ProximityAlarmState>();
  var preferences = await SharedPreferences.getInstance();

  las.alarmSound = preferences.getBool(sharedPreferencesAlarmSoundKey) ?? true;
  las.vibration = preferences.getBool(sharedPreferencesAlarmVibrationKey) ?? true;
  las.notification = preferences.getBool(sharedPreferencesAlarmNotificationKey) ?? true;
  las.update();
}

Future<void> navigateToAlarm(Alarm alarm) async {
  var las = Get.find<ProximityAlarmState>();
  las.currentView = ProximityAlarmViews.map;
  las.update();
  await las.pageController.animateToPage(las.currentView.index, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
  las.mapController.move(alarm.position, initialZoom);
}
