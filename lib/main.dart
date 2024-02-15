import 'dart:async';
import 'dart:io';

import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/views/alarms.dart';
import 'package:location_alarm/views/map.dart';
import 'package:location_alarm/views/settings.dart';
import 'package:location_alarm/views/triggered_alarm_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

/*
 TODO:
 [X] Make it so when locked to user location the map gestures are disabled. (zoom but no moving). move lock on logic to mapOnUpdate. also make it so map immedietly locks on instead of next position update. 
 [ ] Add crash analytics. use sentry.
 [ ] Could split up app state into multiple controllers for better organization and performance. Could use getBuilder Ids to accomplish this.
 [X] Convert hive stuff to just using files for both map cache and settings + alarms storage.
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ProximityAlarmState()); // Inject the global app state into memory. Also initializes a bunch of stuff inside onInit().

  // Load map tile cache
	var las = Get.find<ProximityAlarmState>();
  var cacheDirectory = await getTemporaryDirectory();
  var mapTileCachePath = '${cacheDirectory.path}${Platform.pathSeparator}$mapTileCacheFilename';
	las.mapTileCacheStore = FileCacheStore(mapTileCachePath);

  // Load saved alarms and settings.
	await loadSettingsFromStorage();
  await loadAlarmsFromStorage();

  // Set up local notifications.
  var initializationSettings = InitializationSettings(iOS: DarwinInitializationSettings());
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Set up http overrides. This is needed to increase the number of concurrent http requests allowed. This helps with the map tiles loading.
  HttpOverrides.global = MyHttpOverrides();

  runApp(BetterFeedback(child: const MainApp()));

  // Start a timer for periodic location permission checks
  Timer.periodic(locationPermissionCheckPeriod, (Timer timer) => checkPermissionAndMaybeInitializeUserPositionStream());
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
      theme: locationAlarmTheme,
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}

// Notification stuff
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
int id = 0;

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

Future<void> checkAlarmsOnUserPositionChange() async {
  var las = Get.find<ProximityAlarmState>();

	// Update the map camera position to the user's location
	if (las.followUserLocation)	await navigateMapToUserLocation();

  var activeAlarms = las.alarms.where((alarm) => alarm.active).toList();

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    debugPrint('Alarm Check: Location permission denied. Cannot check for triggered alarms.');
    return;
  }

  var userPosition = las.userLocation;
  if (userPosition == null) {
    debugPrint('Alarm Check: No user position found.');
    return;
  }

  var userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

  var triggeredAlarms = checkIfUserTriggersAlarms(userLatLng, activeAlarms);

  if (triggeredAlarms.isEmpty) {
    debugPrint('Alarm Check: No alarms triggered.');
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Alarm Check: Triggered alarm ${alarm.name}');

  // If an alarm is already triggered, don't show another dialog.
  if (las.alarmIsCurrentlyTriggered) return;

  for (var alarm in triggeredAlarms) {
    if (las.notification) {
      // the notification boolean is always set to true but we might want to add user control later.
      debugPrint('Alarm Check: Sending the user a notification for alarm ${alarm.name}.');
      var notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentBanner: true, presentSound: true),
      );
      await flutterLocalNotificationsPlugin.show(id++, 'Alarm Triggered', 'You have entered the radius of alarm: ${alarm.name}.', notificationDetails);
    }

    // No alarm is currently triggered, so we can show the dialog.
    las.alarmIsCurrentlyTriggered = true;
    showAlarmDialog(NavigationService.navigatorKey.currentContext!, alarm.id);

    // Commence the vibration after the dialog is shown.
    if (las.vibration) {
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
