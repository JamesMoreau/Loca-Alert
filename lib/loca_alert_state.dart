import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:june/june.dart';
import 'package:latlong2/latlong.dart';
import 'package:loca_alert/constants.dart';
import 'package:loca_alert/main.dart';
import 'package:loca_alert/models/alarm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocaAlertState extends JuneState {
	List<Alarm> alarms = <Alarm>[];

	// User Location Stuff
	LatLng? userLocation;

	// EditAlarmDialog Stuff
	Alarm? bufferAlarm;
	late TextEditingController nameInputController;

	// View Stuff
	ProximityAlarmViews currentView = ProximityAlarmViews.alarms;
	late PageController pageController;
	bool alarmIsCurrentlyTriggered = false;

	// MapView stuff
	late MapController mapController;
	bool isPlacingAlarm = false;
	double alarmPlacementRadius = 100;
	bool showMarkersInsteadOfCircles = false;
	Alarm? closestAlarm;
	bool closestAlarmIsInView = false;
	CacheStore? mapTileCacheStore;
	bool followUserLocation = false;

	// User Settings
	bool vibration = true;
	bool notification = true;
	bool showClosestOffScreenAlarm = true;

  // Initializations
  bool notificationPluginIsInitialized = false;

	@override
	void onInit() {
		nameInputController = TextEditingController();

		pageController = PageController(initialPage: currentView.index);

		mapController = MapController();

		super.onInit();
		debugPrint('LocaAlert state initialized.');
	}

	@override
	void onClose() {
		pageController.dispose();
		mapController.dispose();
		if (mapTileCacheStore != null) mapTileCacheStore!.close();
		
		super.onClose();
		debugPrint('LocaAlert state disposed.');
	}
}

// This is used to produce unique ids. Only one instantiation is needed.
final Uuid idGenerator = Uuid();

bool deleteAlarmById(String id) {
	var state = June.getState(LocaAlertState());
	for (var i = 0; i < state.alarms.length; i++) {
		if (state.alarms[i].id == id) {
			state.alarms.removeAt(i);
			state.setState();
			saveAlarmsToStorage(); // update the storage
			return true;
		}
	}

	debugPrint('Error: no alarm $id found to be deleted.');
	return false;
}

Alarm? getAlarmById(String id) {
	var state = June.getState(LocaAlertState());

	for (var alarm in state.alarms) {
		if (alarm.id == id) return alarm;
	}

	return null;
}

// pass your new alarm data here to update proxalarm state. The id field in newAlarmData is ignored. returns success.
bool updateAlarmById(String id, Alarm newAlarmData) {
	var state = June.getState(LocaAlertState());

	for (var alarm in state.alarms) {
		if (alarm.id == id) {
			alarm.name = newAlarmData.name;
			alarm.position = newAlarmData.position;
			alarm.radius = newAlarmData.radius;
			alarm.color = newAlarmData.color;
			alarm.active = newAlarmData.active;
			state.setState();
			saveAlarmsToStorage();
			return true;
		}
	}

	return false;
}

void addAlarm(Alarm alarm) {
	var state = June.getState(LocaAlertState());

	state.alarms.add(alarm);
	state.setState();
	saveAlarmsToStorage();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToStorage() async {
	var state = June.getState(LocaAlertState());
	
	var directory = await getApplicationDocumentsDirectory();
	var alarmsPath = '${directory.path}${Platform.pathSeparator}$alarmsFilename';
	var file = File(alarmsPath);

	var alarmJsons = List<String>.empty(growable: true);
	for (var alarm in state.alarms) {
		var alarmMap = alarmToMap(alarm);
		var alarmJson = jsonEncode(alarmMap);
		alarmJsons.add(alarmJson);
	}

	var json = jsonEncode(alarmJsons);
	await file.writeAsString(json);
	debugPrint('Saved alarms to storage: $alarmJsons.');
}

Future<void> loadAlarmsFromStorage() async {
	var state = June.getState(LocaAlertState());

	var directory = await getApplicationDocumentsDirectory();
	var alarmsPath = '${directory.path}${Platform.pathSeparator}$alarmsFilename';
	var file = File(alarmsPath);

	if (!file.existsSync()) {
		debugPrint('Warning: No alarms file found in storage.');
		return;
	}

	var alarmJsons = await file.readAsString();
	if (alarmJsons.isEmpty) {
		debugPrint('Warning: No alarms found in storage.');
		return;
	}

	var alarmJsonsList = jsonDecode(alarmJsons) as List;
	for (var alarmJson in alarmJsonsList) {
		var alarmMap = jsonDecode(alarmJson as String) as Map<String, dynamic>;
		var alarm = alarmFromMap(alarmMap);
		state.alarms.add(alarm);
	}

	state.setState();
	debugPrint('Loaded alarms from storage.');
}

Future<void> loadSettingsFromStorage() async {
	var state = June.getState(LocaAlertState());

	var directory = await getApplicationDocumentsDirectory();
	var settingsPath = '${directory.path}${Platform.pathSeparator}$settingsFilename';
	var settingsFile = File(settingsPath);

	if (!settingsFile.existsSync()) {
		debugPrint('Warning: No settings file found in storage.');
		return;
	}

	var settingsJson = await settingsFile.readAsString();
	if (settingsJson.isEmpty) {
		debugPrint('Error: No settings found in storage.');
		return;
	}

	var settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
	state.vibration = settingsMap[settingsAlarmVibrationKey] as bool;
	state.notification = settingsMap[settingsAlarmNotificationKey] as bool;
	state.showClosestOffScreenAlarm = settingsMap[settingsShowClosestOffScreenAlarmKey] as bool;
	debugPrint('Loaded settings from storage.');
}

Future<void> clearAlarmsFromStorage() async {
	var directory = await getApplicationDocumentsDirectory();
	var alarmsPath = '${directory.path}${Platform.pathSeparator}$alarmsFilename';
	var alarmsFile = File(alarmsPath);

	if (!alarmsFile.existsSync()) {
		debugPrint('Warning: No alarms file found in storage. Cannot clear alarms.');
		return;
	}

	await alarmsFile.delete();
	debugPrint('Cleared alarms from storage.');
}

void resetAlarmPlacementUIState() {
	var state = June.getState(LocaAlertState());
	state.isPlacingAlarm = false;
	state.alarmPlacementRadius = 100;
}

void changeVibration({required bool newValue}) {
	var state = June.getState(LocaAlertState());
	state.vibration = newValue;
	state.setState();
	saveSettingsToStorage();
}

void changeAlarmNotification({required bool newValue}) {
	var state = June.getState(LocaAlertState());
	state.notification = newValue;
	state.setState();
	saveSettingsToStorage();
}

void changeShowClosestOffScreenAlarm({required bool newValue}) {
	var state = June.getState(LocaAlertState());
	state.showClosestOffScreenAlarm = newValue;
	state.setState();
	saveSettingsToStorage();
}

Future<void> saveSettingsToStorage() async {
	var state = June.getState(LocaAlertState());
	var directory = await getApplicationDocumentsDirectory();
	var settingsPath = '${directory.path}${Platform.pathSeparator}$settingsFilename';
	var settingsFile = File(settingsPath);

	var settingsMap = <String, dynamic>{
		settingsAlarmVibrationKey:            state.vibration,
		settingsAlarmNotificationKey:         state.notification,
		settingsShowClosestOffScreenAlarmKey: state.showClosestOffScreenAlarm,
	};

	var settingsJson = jsonEncode(settingsMap);
	await settingsFile.writeAsString(settingsJson);

	debugPrint('Saved settings to storage.');
}