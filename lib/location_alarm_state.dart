// ignore_for_file: inference_failure_on_function_invocation

import 'dart:async';
import 'dart:convert';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/main.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/views/map.dart';
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
			saveAlarmsToHive(); // update the storage
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
			saveAlarmsToHive();
			return true;
		}
	}

	return false;
}

void addAlarm(Alarm alarm) {
	var las = Get.find<ProximityAlarmState>();

	las.alarms.add(alarm);
	las.update();
	saveAlarmsToHive();
}

// This saves all current alarms to shared preferences. Should be called everytime the alarms state is changed.
Future<void> saveAlarmsToHive() async {
	var las = Get.find<ProximityAlarmState>();
	var box = Hive.box(mainHiveBox);	

	var alarmJsons = <String>[];
	for (var alarm in las.alarms) {
		var alarmJson = alarmToJson(alarm);
		var alarmJsonString = jsonEncode(alarmJson);
		alarmJsons.add(alarmJsonString);
	}

	debugPrint('Saving alarms to hive: $alarmJsons');
	await box.put(alarmsKey, alarmJsons);
}

Future<void> loadAlarmsAndSettingsFromHive() async {
	var las = Get.find<ProximityAlarmState>();
	var box = Hive.box(mainHiveBox);

	var alarmJsons = box.get(alarmsKey);
	if (alarmJsons == null) {
		debugPrint('Warning: No alarms found in hive.');
		return;
	}

	for (var alarmJsonString in alarmJsons as List<String>) {
		var alarmJson = jsonDecode(alarmJsonString);
		var alarm = alarmFromJson(alarmJson as Map<String, dynamic>);
		debugPrint(alarmJsonString);

		las.alarms.add(alarm);
	}

	las.alarmSound = box.get(settingsAlarmSoundKey, defaultValue: true) as bool;
	las.vibration = box.get(settingsAlarmVibrationKey, defaultValue: true) as bool;
	las.notification = box.get(settingsAlarmNotificationKey, defaultValue: true) as bool;
	las.showClosestOffScreenAlarm = box.get(settingsShowClosestOffScreenAlarmKey, defaultValue: true) as bool;

	las.update();
}

Future<void> clearAlarmsFromHive() async {
	var box = Hive.box(mainHiveBox);
	await box.delete(alarmsKey);
	debugPrint('Cleared alarms from hive.');
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
	saveSettingsToHive();
}

void changeVibration({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.vibration = newValue;
	las.update();
	saveSettingsToHive();
}

void changeAlarmNotification({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.notification = newValue;
	las.update();
	saveSettingsToHive();
}

void changeShowClosestOffScreenAlarm({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.showClosestOffScreenAlarm = newValue;
	las.update();
	saveSettingsToHive();
}

Future<void> saveSettingsToHive() async {
	debugPrint('Saving settings to hive');

	var las = Get.find<ProximityAlarmState>();
	var settings = Hive.box(mainHiveBox);

	await settings.put(settingsAlarmSoundKey, las.alarmSound);
	await settings.put(settingsAlarmVibrationKey, las.vibration);
	await settings.put(settingsAlarmNotificationKey, las.notification);
	await settings.put(settingsShowClosestOffScreenAlarmKey, las.showClosestOffScreenAlarm);
}

Future<void> navigateToAlarm(Alarm alarm) async {
	var las = Get.find<ProximityAlarmState>();
	
	// Switch to the map view
	las.currentView = ProximityAlarmViews.map;
	las.update();
	las.pageController.jumpToPage(las.currentView.index);

	// Move the map to the alarm
	if (las.mapController != null) las.mapController!.move(alarm.position, initialZoom);
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
		await navigateMapToUserLocation();
	}

	// The remaining case is locationPermissionIsGranted && positionStreamIsInitialized. In which case, do nothing.
}
