import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/main.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/views/map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProximityAlarmState extends GetxController {
	List<Alarm> alarms = <Alarm>[];

	// User Location Stuff
	LatLng? userLocation;
	StreamSubscription<Position>? positionStream;

	// View Stuff
	ProximityAlarmViews currentView = ProximityAlarmViews.alarms;
	late PageController pageController;

	// Alarm Stuff
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
	String mapTileCachePath = '';

	// Settings
	bool alarmSound = true;
	bool vibration = true;
	bool notification = true;
	bool showClosestOffScreenAlarm = true;

	@override
	void onInit() {
		pageController = PageController(initialPage: currentView.index);

		super.onInit();
		debugPrint('ProximityAlarmState initialized.');
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

void changeShowClosestOffScreenAlarm({required bool newValue}) {
	var las = Get.find<ProximityAlarmState>();
	las.showClosestOffScreenAlarm = newValue;
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
	await preferences.setBool(sharedPreferencesShowClosestOffScreenAlarmKey, las.showClosestOffScreenAlarm);
}

Future<void> loadSettingsFromSharedPreferences() async {
	var las = Get.find<ProximityAlarmState>();
	var preferences = await SharedPreferences.getInstance();

	las.alarmSound = preferences.getBool(sharedPreferencesAlarmSoundKey) ?? true;
	las.vibration = preferences.getBool(sharedPreferencesAlarmVibrationKey) ?? true;
	las.notification = preferences.getBool(sharedPreferencesAlarmNotificationKey) ?? true;
	las.showClosestOffScreenAlarm = preferences.getBool(sharedPreferencesShowClosestOffScreenAlarmKey) ?? true;
	las.update();
}

Future<void> navigateToAlarm(Alarm alarm) async {
	var las = Get.find<ProximityAlarmState>();
	las.currentView = ProximityAlarmViews.map;
	las.update();
	await las.pageController.animateToPage(las.currentView.index, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
	las.mapController.move(alarm.position, initialZoom);
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
