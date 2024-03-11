import 'dart:async';
import 'dart:io';

import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:june/june.dart';
import 'package:latlong2/latlong.dart';
import 'package:loca_alert/constants.dart';
import 'package:loca_alert/loca_alert_state.dart';
import 'package:loca_alert/models/alarm.dart';
import 'package:loca_alert/views/alarms.dart';
import 'package:loca_alert/views/map.dart';
import 'package:loca_alert/views/settings.dart';
import 'package:loca_alert/views/triggered_alarm_dialog.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

/*
 TODO:
 see if i can remove dio_cache_interceptor.
*/

void main() async {
  // Check that we are on a supported platform
  if ( !(Platform.isIOS || Platform.isAndroid) ) {
    debugPrint('Error: This app is not supported on this platform. Supported platforms are iOS and Android.');
    return;
  }
  
  runApp(MainApp());

  // Setup state
	var state = June.getState(LocaAlertState());

  // Set up location
  await location.enableBackgroundMode();
  location.onLocationChanged.listen((location) async {  // Register the location update callback
    if (location.latitude == null || location.longitude == null) return; // This shouldn't happen, but just in case.
    
    var state = June.getState(LocaAlertState());
    state.userLocation = LatLng(location.latitude!, location.longitude!);
    state.setState();

    await checkAlarms(); // Check if the user has entered the radius of any alarms.

    // Update the map camera position to the user's location
    if (state.followUserLocation && state.currentView == ProximityAlarmViews.map)	await moveMapToUserLocation();
  });
  Timer.periodic(Duration(seconds: 20), (timer) async { // Check periodically if the location permission has been denied. If so, cancel the location updates.
    var state = June.getState(LocaAlertState());
    var permission = await location.hasPermission();

    if (permission == PermissionStatus.denied || permission == PermissionStatus.deniedForever) {
      state.userLocation = null;
      state.followUserLocation = false;
      state.setState();
    }
  });
  
  // Load saved alarms and settings.
	await loadSettingsFromStorage();
  await loadAlarmsFromStorage();

  // Set up local notifications. This needs to be done before alarms are checked.
  var initializationSettings = InitializationSettings(iOS: DarwinInitializationSettings());
  state.notificationPluginIsInitialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings) ?? false;
  state.setState(); // Notify the ui that the notifications plugin is intialized.

  // Set up http overrides. This is needed to increase the number of concurrent http requests allowed. This helps with the map tiles loading.
  HttpOverrides.global = MyHttpOverrides();

  // Load map tile cache
  var cacheDirectory = await getApplicationCacheDirectory();
  var mapTileCachePath = '${cacheDirectory.path}${Platform.pathSeparator}$mapTileCacheFilename';
	state.mapTileCacheStore = FileCacheStore(mapTileCachePath);
  state.setState(); // Notify the ui that the map tile cache is loaded.
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
      home: JuneBuilder(
        () => LocaAlertState(),
        builder: (state) {

          // Check that everything is initialized before building the app. Right now, the only thing that needs to be initialized is the map tile cache and notification plugin.
          var appIsInitialized = state.mapTileCacheStore == null || !state.notificationPluginIsInitialized;
          if (appIsInitialized) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

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
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
							child: ClipRRect(
								borderRadius: BorderRadius.only(
									topLeft: Radius.circular(50),
									topRight: Radius.circular(50),
								),
								child: NavigationBar(
									elevation: 3,
									onDestinationSelected: (int index) {
										state.currentView = ProximityAlarmViews.values[index];
										debugPrint('Navigating to ${state.currentView}.');
										state.setState();
										state.pageController.jumpToPage(index);
										// state.pageController.animateToPage(index,	duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
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
						),
          );
        },
      ),
      theme: locationAlarmTheme,
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}

/* GLOBALS */

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
int id = 0;

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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

Location location = Location();

/* END GLOBALS */

Future<void> checkAlarms() async {
  var state = June.getState(LocaAlertState());
  var activeAlarms = state.alarms.where((alarm) => alarm.active).toList();

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    debugPrint('Alarm Check: Location permission denied. Cannot check for triggered alarms.');
    return;
  }

  var userPosition = state.userLocation;
  if (userPosition == null) {
    debugPrint('Alarm Check: No user position found.');
    return;
  }

  var triggeredAlarms = checkIfUserTriggersAlarms(userPosition, activeAlarms);
  if (triggeredAlarms.isEmpty) {
    debugPrint('Alarm Check: No alarms triggered.');
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Alarm Check: Triggered alarm ${alarm.name} at timestamp ${DateTime.now()}.');

  // If another alarm is already triggered, ignore the new alarm.
  if (state.alarmIsCurrentlyTriggered) return;

  var triggeredAlarm = triggeredAlarms[0]; // For now, we only handle one triggered alarm at a time.
  triggeredAlarm.active = false; // Deactivate the alarm so it doesn't trigger again upon user location changing.
  if (state.notification) { // the notification boolean is always set to true but we might want to add user control later.
    debugPrint('Alarm Check: Sending the user a notification for alarm ${triggeredAlarm.name}.');
    var notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentBanner: true, presentSound: true),
    );
    await flutterLocalNotificationsPlugin.show(id++, 'Alarm Triggered', 'You have entered the radius of alarm: ${triggeredAlarm.name}.', notificationDetails);
  }

  // No alarm is currently triggered, so we can show the dialog.
  state.alarmIsCurrentlyTriggered = true;
  showAlarmDialog(NavigationService.navigatorKey.currentContext!, triggeredAlarm.id);

  if (state.vibration) {
    for (var i = 0; i < numberOfTriggeredAlarmVibrations; i++) {
      await Vibration.vibrate(duration: 1000);
      await Future<void>.delayed(Duration(milliseconds: 1000));
    }
  }
}
