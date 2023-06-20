import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/home.dart';
import 'package:proxalarm/proxalarm_state.dart';
import 'package:intl/intl.dart';
import 'alarm.dart';

/* 
  TODO:
  switch map tile provider (mapbox, thunderforest, etc)
  checkout mapbox: https://docs.fleaflet.dev/tile-servers/using-mapbox
  tile chaching
  show some sort icon on map for alarm if too zoomed out to see the circle. (could use current zoom level to determine this).
  Logo
  show something when user is too zoomed in. Use current zoom level to determine this.
  get distance to closest alarm. have some sort of ui layer that points towards the alarm from current location if it is offscreen.
*/

void main() {
  Get.put(ProxalarmState()); // Inject the global app state into memory.
  
  loadAlarmsFromSharedPreferences();
  loadSettingsFromSharedPreferences();

  // Set off periodic alarm checks.
  Timer.periodic(alarmCheckPeriod, (timer) => periodicAlarmCheck());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
      theme: proxalarmTheme,
    );
  }
}

void periodicAlarmCheck() async {
  // debugPrint('Should see me every 5 seconds. ${DateFormat('HH:mm:ss').format(DateTime.now())}');
  ProxalarmState ps = Get.find<ProxalarmState>();

  var activeAlarms = ps.alarms.where((alarm) => alarm.active).toList();

  var userPosition = await Geolocator.getLastKnownPosition();
  if (userPosition == null) {
    debugPrint('No user position found.');
    return;
  }

  var userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

  var triggeredAlarms = checkIfUserTriggersAlarms(userLatLng, activeAlarms);

  if (triggeredAlarms.isEmpty) {
    debugPrint('No alarms triggered.');
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Triggered alarm: ${alarm.name}');
}
