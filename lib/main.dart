import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  add user position marker to map by hand.
  tile chaching
  show some sort icon on map for alarm if too zoomed out to see the circle. (could use current zoom level to determine this).
  App Logo
  show something when user is too zoomed in. Use current zoom level to determine this.
  get distance to closest alarm. have some sort of ui layer that points towards the alarm from current location if it is offscreen.
*/

// Notification stuff
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
int id = 0;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ProximityAlarmState()); // Inject the global app state into memory.

  // Load saved alarms and settings from shared preferences.
  loadAlarmsFromSharedPreferences();
  loadSettingsFromSharedPreferences();

  // Set up local notifications.
  var initializationSettings = InitializationSettings(iOS: DarwinInitializationSettings());
  flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Set off periodic alarm checks.
  Timer.periodic(alarmCheckPeriod, (timer) => periodicAlarmCheck());

  // Get location permission
  Geolocator.requestPermission();

  // Set up http overrides. This is needed to increase the number of concurrent http requests allowed. This helps with the map tiles loading.
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MainApp());
}

enum ProximityAlarmViews { alarms, map, settings }

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set preferred orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
                  // state.pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                  state.pageController.jumpToPage(index);
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
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Periodic Alarm Check: Triggered alarm ${alarm.name}');

  // If an alarm is already triggered, don't show another dialog.
  if (pas.alarmIsCurrentlyTriggered) return;

  for (var alarm in triggeredAlarms) {
    // if (pas.settings.sound) {
    //   debugPrint('Playing sound.');
    //   await AudioCache().play('alarm.mp3');
    // }

    if (pas.notification) {
      // the notification boolean is always set to true but we might want to add user control later.
      debugPrint('Sending the user a notification for alarm ${alarm.name}.');
      var notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentBanner: true, presentSound: true),
      );
      await flutterLocalNotificationsPlugin.show(id++, 'Alarm Triggered', 'You have entered the radius of alarm: ${alarm.name}.', notificationDetails);
    }

    // No alarm is currently triggered, so we can show the dialog.
    pas.alarmIsCurrentlyTriggered = true;
    showAlarmDialog(NavigationService.navigatorKey.currentContext!, alarm.id);

    if (pas.vibration) {
      for (var i = 0; i < numberOfTriggeredAlarmVibrations; i++) {
        await Vibration.vibrate(duration: 1000);
        await Future<void>.delayed(Duration(milliseconds: 1000));
      }
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  final int maxConnections = 8;
  
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var client = super.createHttpClient(context);
    client.maxConnectionsPerHost = maxConnections;
    return client;
  }
}
