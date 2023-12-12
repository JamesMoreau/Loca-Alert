import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proximityalarm/alarm.dart';
import 'package:proximityalarm/constants.dart';
import 'package:proximityalarm/home.dart';
import 'package:proximityalarm/proximity_alarm_state.dart';
import 'package:proximityalarm/triggered_alarm_dialog.dart';
import 'package:vibration/vibration.dart';

/* 
  TODO:
  change name to proximity alarm
  actually make alarm work
  alarm notification
  switch map tile provider (mapbox, thunderforest, etc)
  checkout mapbox: https://docs.fleaflet.dev/tile-servers/using-mapbox
  tile chaching
  show some sort icon on map for alarm if too zoomed out to see the circle. (could use current zoom level to determine this).
  App Logo
  show something when user is too zoomed in. Use current zoom level to determine this.
  get distance to closest alarm. have some sort of ui layer that points towards the alarm from current location if it is offscreen.
*/

void main() {
  Get.put(ProximityAlarmState()); // Inject the global app state into memory.

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
      debugShowCheckedModeBanner: false,
      home: Home(),
      theme: ProximityAlarmTheme,
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

Future<void> periodicAlarmCheck() async {
  // debugPrint('Should see me every 5 seconds. ${DateFormat('HH:mm:ss').format(DateTime.now())}');
  var pas = Get.find<ProximityAlarmState>();

  var activeAlarms = pas.alarms.where((alarm) => alarm.active).toList();

  var userPosition = await Geolocator.getLastKnownPosition();
  if (userPosition == null) {
    debugPrint('Periodic Alarm Check: No user position found.');
    return;
  }

  var userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

  var triggeredAlarms = checkIfUserTriggersAlarms(userLatLng, activeAlarms);

  if (triggeredAlarms.isEmpty) {
    debugPrint('Periodic Alarm Check: No alarms triggered.');
    await Vibration.cancel();
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Periodic Alarm Check: Triggered alarm ${alarm.name}');

  // If an alarm is already triggered, don't show another dialog.
  if (pas.alarmIsCurrentlyTriggered) return;

  for (var alarm in triggeredAlarms) {
    if (pas.vibration) {
      await Vibration.vibrate();
    }

    // if (pas.settings.sound) {d
    //   debugPrint('Playing sound.');
    //   await AudioCache().play('alarm.mp3');
    // }

    // if (pas.showNotification) {
    //   debugPrint('Showing notification.');
    // }

    // No alarm is currently triggered, so we can show the dialog.
    pas.alarmIsCurrentlyTriggered = true;
    showAlarmDialog(NavigationService.navigatorKey.currentContext!, alarm.id);
  }
}
