import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/home.dart';
import 'package:proxalarm/proxalarm_state.dart';

import 'alarm.dart';

/* 
  TODO:
    short term:
    settings: alarm sound, vibration?, location settings

    long term:
    switch map tile provider (mapbox, thunderforest, etc)
    checkout mapbox: https://docs.fleaflet.dev/tile-servers/using-mapbox
    go alarm on map. using MapController
    tile chaching
    go to user location on map if offscreen.
    show some sort icon on map for alarm if too zoomed out to see the circle. (could use current zoom level to determine this).
    Logo
    show something when user is too zoomed in. Use current zoom level to determine this.
    get distance to closest alarm. have some sort of ui layer that points towards the alarm from current location if it is offscreen.
*/

enum Views { map, alarms }

void main() {
  Get.put(ProxalarmState()); // Inject the global app state into memory.
  loadAlarmsFromSharedPreferences();

  // Set off periodic alarm checks.
  Timer.periodic(Duration(seconds: 5), (timer) => periodicAlarmCheck());

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
  ProxalarmState ps = Get.find<ProxalarmState>();

    var activeAlarms = ps.alarms.where((alarm) => alarm.active).toList();

    var userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    var userLocation = LatLng(userPosition.latitude, userPosition.longitude);

    var triggeredAlarms = checkIfUserTriggersAlarms(userLocation, activeAlarms);

    if (triggeredAlarms.isEmpty) {
      debugPrint('No alarms triggered.');
      return;
    }

    for (var alarm in triggeredAlarms) debugPrint('Triggered alarm: ${alarm.name}');
}