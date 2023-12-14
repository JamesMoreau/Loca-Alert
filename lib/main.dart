import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxmity_alarm/alarm.dart';
import 'package:proxmity_alarm/alarms_view.dart';
import 'package:proxmity_alarm/constants.dart';
import 'package:proxmity_alarm/map_view.dart';
import 'package:proxmity_alarm/proximity_alarm_state.dart';
import 'package:proxmity_alarm/settings_view.dart';
import 'package:proxmity_alarm/triggered_alarm_dialog.dart';
import 'package:vibration/vibration.dart';

/* 
  TODO:
  fix black screen thing
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

enum ProximityAlarmViews { alarms, map, settings }

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GetBuilder<ProximityAlarmState>(
        builder: (state) {
          return Scaffold(
            body: PageView(
              controller: state.pageController,
              physics: NeverScrollableScrollPhysics(), // Disable swipe gesture to change pages
              children: [
                AlarmsView(),
                MapView(),
                SettingsView(),
              ],
            ),
            extendBody: true,
            bottomNavigationBar: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              child: NavigationBar(
                elevation: 3,
                onDestinationSelected: (int index) {
                  state.currentView = ProximityAlarmViews.values[index];
                  debugPrint('Navigating to ${state.currentView}.');
                  state.update();
                  state.pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                selectedIndex: state.currentView.index,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.pin_drop_rounded),
                    label: 'Alarms',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_rounded),
                    label: 'Map',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      theme: proximityAlarmTheme,
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
    // await Vibration.cancel();
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Periodic Alarm Check: Triggered alarm ${alarm.name}');

  // If an alarm is already triggered, don't show another dialog.
  if (pas.alarmIsCurrentlyTriggered) return;

  for (var alarm in triggeredAlarms) {
    if (pas.vibration) {
      await Vibration.vibrate(duration: 5000);
    }

    // if (pas.settings.sound) {
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
