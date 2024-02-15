import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/main.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/views/map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProximityAlarmState extends GetxController {
	List<Alarm> alarms = <Alarm>[];

	// User Location Stuff
	LatLng? userLocation;
	StreamSubscription<Position>? positionStream;

	// View Stuff
	ProximityAlarmViews currentView = ProximityAlarmViews.alarms;
	late PageController pageController;
	bool alarmIsCurrentlyTriggered = false;

	// MapView stuff
	MapController? mapController;
	bool isPlacingAlarm = false;
	double alarmPlacementRadius = 100;
	bool showMarkersInsteadOfCircles = false;
	Alarm? closestAlarm;
	bool closestAlarmIsInView = false;
	CacheStore? mapTileCacheStore;
	bool followUserLocation = false;

	// Settings
	bool alarmSound = true;
	bool vibration = true;
	bool notification = true;
	bool showClosestOffScreenAlarm = true;

	@override
	void onInit() {
		pageController = PageController(initialPage: currentView.index);

		mapController = MapController();

		super.onInit();
		debugPrint('Location Alarm state initialized.');
	}

	@override
	void onClose() {
		if (positionStream != null) positionStream!.cancel();
		super.onClose();
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
			saveAlarmsToStorage(); // update the storage
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
			saveAlarmsToStorage();
			return true;
		}
	}

	return false;
}

void addAlarm(Alarm alarm) {
	var las = Get.find<ProximityAlarmState>();

	las.alarms.add(alarm);
	las.update();
	saveAlarmsToStorage();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToStorage() async {
	var las = Get.find<ProximityAlarmState>();
	
	var directory = await getApplicationDocumentsDirectory();
	var alarmsPath = '${directory.path}${Platform.pathSeparator}$alarmsFilename';
	var file = File(alarmsPath);

	var alarmJsons = List<String>.empty(growable: true);
	for (var alarm in las.alarms) {
		var alarmMap = alarmToMap(alarm);
		var alarmJson = jsonEncode(alarmMap);
		alarmJsons.add(alarmJson);
	}

	var json = jsonEncode(alarmJsons);
	await file.writeAsString(json);
	debugPrint('Saved alarms to storage: $alarmJsons');
}

Future<void> loadAlarmsFromStorage() async {
	var las = Get.find<ProximityAlarmState>();

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
		las.alarms.add(alarm);
	}

	las.update();
	debugPrint('Loaded alarms from storage');
}

Future<void> loadSettingsFromStorage() async {
	var las = Get.find<ProximityAlarmState>();

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
	las.alarmSound = settingsMap[settingsAlarmSoundKey] as bool;
	las.vibration = settingsMap[settingsAlarmVibrationKey] as bool;
	las.notification = settingsMap[settingsAlarmNotificationKey] as bool;
	las.showClosestOffScreenAlarm = settingsMap[settingsShowClosestOffScreenAlarmKey] as bool;
	debugPrint('Loaded settings from storage');
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
	var las = Get.find<ProximityAlarmState>();
	las.isPlacingAlarm = false;
	las.alarmPlacementRadius = 100;
}

void changeAlarmSound({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.alarmSound = newValue;
	las.update();
	saveSettingsToStorage();
}

void changeVibration({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.vibration = newValue;
	las.update();
	saveSettingsToStorage();
}

void changeAlarmNotification({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.notification = newValue;
	las.update();
	saveSettingsToStorage();
}

void changeShowClosestOffScreenAlarm({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.showClosestOffScreenAlarm = newValue;
	las.update();
	saveSettingsToStorage();
}

Future<void> saveSettingsToStorage() async {
	var las = Get.find<ProximityAlarmState>();
	var directory = await getApplicationDocumentsDirectory();
	var settingsPath = '${directory.path}${Platform.pathSeparator}$settingsFilename';
	var settingsFile = File(settingsPath);

	var settingsMap = <String, dynamic>{
		settingsAlarmSoundKey: las.alarmSound,
		settingsAlarmVibrationKey: las.vibration,
		settingsAlarmNotificationKey: las.notification,
		settingsShowClosestOffScreenAlarmKey: las.showClosestOffScreenAlarm,
	};

	var settingsJson = jsonEncode(settingsMap);
	await settingsFile.writeAsString(settingsJson);

	debugPrint('Saved settings to storage.');
}

Future<void> checkPermissionAndMaybeInitializeUserPositionStream() async {
	var las = Get.find<ProximityAlarmState>();

	var permission = await Geolocator.checkPermission();
	var locationPermissionIsGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
	var positionStreamIsInitialized = las.positionStream != null;

	if (!locationPermissionIsGranted && !positionStreamIsInitialized) {
		debugPrint('Location permission denied and position stream uninitialized. Cannot initialize user location stream.');
		return;
	}

	if (!locationPermissionIsGranted && positionStreamIsInitialized) {
		debugPrint('Location permission denied and position stream initialized. Cancelling user location stream.');
		await las.positionStream!.cancel();
		las.positionStream = null;
		las.userLocation = null;
		las.update(); // Trigger a rebuild when the user location stream is cancelled so the user no longer shows on the map
		return;
	}

	if (locationPermissionIsGranted && !positionStreamIsInitialized) {
		debugPrint('Location permission granted and position stream uninitialized. Initializing user location stream.');
		las.positionStream = Geolocator.getPositionStream(
			locationSettings: LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10),
		).listen((Position position) {
			las.userLocation = LatLng(position.latitude, position.longitude);
			checkAlarmsOnUserPositionChange(); // Check if the user has entered the radius of any alarms
			las.update(); // Trigger a rebuild when the user location is updated
		});

		las.userLocation = null;
		var position = await Geolocator.getLastKnownPosition();
		if (position != null) las.userLocation = LatLng(position.latitude, position.longitude);
		las.update();
	}

	// The remaining case is locationPermissionIsGranted && positionStreamIsInitialized. In which case, do nothing.
}
