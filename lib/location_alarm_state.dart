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

class LocationAlarmState extends GetxController {
	List<Alarm> alarms = <Alarm>[];

	// User Location Stuff
	LatLng? userLocation;
	StreamSubscription<Position>? positionStream;

	// EditAlarmDialog Stuff
	// String? alarmBeingEditedId;
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

	// Settings
	bool alarmSound = true;
	bool vibration = true;
	bool notification = true;
	bool showClosestOffScreenAlarm = true;

	@override
	void onInit() {
		nameInputController = TextEditingController();

		pageController = PageController(initialPage: currentView.index);

		mapController = MapController();

		super.onInit();
		debugPrint('Location Alarm state initialized.');
	}

	@override
	void onClose() {
		if (positionStream != null) positionStream!.cancel();
		pageController.dispose();
		mapController.dispose();
		if (mapTileCacheStore != null) mapTileCacheStore!.close();
		
		super.onClose();
		debugPrint('Location Alarm state disposed.');
	}
}

// This is used to produce unique ids. Only one instantiation is needed.
final Uuid idGenerator = Uuid();

bool deleteAlarmById(String id) {
	var state = Get.find<LocationAlarmState>();
	for (var i = 0; i < state.alarms.length; i++) {
		if (state.alarms[i].id == id) {
			state.alarms.removeAt(i);
			state.update();
			saveAlarmsToStorage(); // update the storage
			return true;
		}
	}

	debugPrint('Error: no alarm $id found to be deleted.');
	return false;
}

Alarm? getAlarmById(String id) {
	var state = Get.find<LocationAlarmState>();

	for (var alarm in state.alarms) {
		if (alarm.id == id) return alarm;
	}

	return null;
}

// pass your new alarm data here to update proxalarm state. The id field in newAlarmData is ignored. returns success.
bool updateAlarmById(String id, Alarm newAlarmData) {
	var state = Get.find<LocationAlarmState>();

	for (var alarm in state.alarms) {
		if (alarm.id == id) {
			alarm.name = newAlarmData.name;
			alarm.position = newAlarmData.position;
			alarm.radius = newAlarmData.radius;
			alarm.color = newAlarmData.color;
			alarm.active = newAlarmData.active;
			state.update();
			saveAlarmsToStorage();
			return true;
		}
	}

	return false;
}

void addAlarm(Alarm alarm) {
	var state = Get.find<LocationAlarmState>();

	state.alarms.add(alarm);
	state.update();
	saveAlarmsToStorage();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToStorage() async {
	var state = Get.find<LocationAlarmState>();
	
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
	debugPrint('Saved alarms to storage: $alarmJsons');
}

Future<void> loadAlarmsFromStorage() async {
	var state = Get.find<LocationAlarmState>();

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

	state.update();
	debugPrint('Loaded alarms from storage');
}

Future<void> loadSettingsFromStorage() async {
	var state = Get.find<LocationAlarmState>();

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
	state.alarmSound = settingsMap[settingsAlarmSoundKey] as bool;
	state.vibration = settingsMap[settingsAlarmVibrationKey] as bool;
	state.notification = settingsMap[settingsAlarmNotificationKey] as bool;
	state.showClosestOffScreenAlarm = settingsMap[settingsShowClosestOffScreenAlarmKey] as bool;
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
	var state = Get.find<LocationAlarmState>();
	state.isPlacingAlarm = false;
	state.alarmPlacementRadius = 100;
}

void changeAlarmSound({required bool newValue}) {
	var state = Get.find<LocationAlarmState>();
	state.alarmSound = newValue;
	state.update();
	saveSettingsToStorage();
}

void changeVibration({required bool newValue}) {
	var state = Get.find<LocationAlarmState>();
	state.vibration = newValue;
	state.update();
	saveSettingsToStorage();
}

void changeAlarmNotification({required bool newValue}) {
	var state = Get.find<LocationAlarmState>();
	state.notification = newValue;
	state.update();
	saveSettingsToStorage();
}

void changeShowClosestOffScreenAlarm({required bool newValue}) {
	var state = Get.find<LocationAlarmState>();
	state.showClosestOffScreenAlarm = newValue;
	state.update();
	saveSettingsToStorage();
}

Future<void> saveSettingsToStorage() async {
	var state = Get.find<LocationAlarmState>();
	var directory = await getApplicationDocumentsDirectory();
	var settingsPath = '${directory.path}${Platform.pathSeparator}$settingsFilename';
	var settingsFile = File(settingsPath);

	var settingsMap = <String, dynamic>{
		settingsAlarmSoundKey: state.alarmSound,
		settingsAlarmVibrationKey: state.vibration,
		settingsAlarmNotificationKey: state.notification,
		settingsShowClosestOffScreenAlarmKey: state.showClosestOffScreenAlarm,
	};

	var settingsJson = jsonEncode(settingsMap);
	await settingsFile.writeAsString(settingsJson);

	debugPrint('Saved settings to storage.');
}

Future<void> checkPermissionAndMaybeInitializeUserPositionStream() async {
	var state = Get.find<LocationAlarmState>();

	var permission = await Geolocator.checkPermission();
	var locationPermissionIsGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
	var positionStreamIsInitialized = state.positionStream != null;

	if (!locationPermissionIsGranted && !positionStreamIsInitialized) {
		debugPrint('Location permission denied and position stream uninitialized. Cannot initialize user location stream.');
		return;
	}

	if (!locationPermissionIsGranted && positionStreamIsInitialized) {
		debugPrint('Location permission denied and position stream initialized. Cancelling user location stream.');
		await state.positionStream!.cancel();
		state.positionStream = null;
		state.userLocation = null;
		state.update(); // Trigger a rebuild when the user location stream is cancelled so the user no longer shows on the map.
		return;
	}

	if (locationPermissionIsGranted && !positionStreamIsInitialized) {
		debugPrint('Location permission granted and position stream uninitialized. Initializing user location stream.');
		state.positionStream = Geolocator.getPositionStream(
			locationSettings: LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10),
		).listen((Position position) async {
			state.userLocation = LatLng(position.latitude, position.longitude);
			
			await checkAlarmsOnUserPositionChange(); // Check if the user has entered the radius of any alarms.
			
			// Update the map camera position to the user's location
			if (state.followUserLocation)	await moveMapToUserLocation();
			
			state.update(); // Trigger a rebuild when the user location is updated.
		});

		state.userLocation = null;
		var position = await Geolocator.getLastKnownPosition();
		if (position != null) state.userLocation = LatLng(position.latitude, position.longitude);
				
		state.update();
	}

	// The remaining case is locationPermissionIsGranted && positionStreamIsInitialized. In which case, do nothing.
}
