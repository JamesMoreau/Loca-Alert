import 'dart:async';
import 'dart:io';

import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:june/june.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/views/alarms.dart';
import 'package:location_alarm/views/map.dart';
import 'package:location_alarm/views/settings.dart';
import 'package:location_alarm/views/triggered_alarm_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibration/vibration.dart';

/*
 TODO:
 - add distance value to off screen alarm.
 - move dsn to environment variable.
 - add build number to app.
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://bc7b8e77243b57aa0fac687ffc2ed77e@o4506730977689600.ingest.sentry.io/4506730979852288';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(BetterFeedback(child: MainApp())),
  );
  
	var state = June.getState(LocationAlarmState());

  // Load saved alarms and settings.
	await loadSettingsFromStorage();
  await loadAlarmsFromStorage();

  // Set up local notifications. This needs to be done before alarms are checked.
  var initializationSettings = InitializationSettings(iOS: DarwinInitializationSettings());
  state.notificationPluginIsInitialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings) ?? false;
  state.setState(); // Notify the ui that the notifications plugin is intialized.

  // Start a timer for periodic location permission checks
  Timer.periodic(locationPermissionCheckPeriod, (Timer timer) => checkPermissionAndMaybeInitializeUserPositionStream());
	await checkPermissionAndMaybeInitializeUserPositionStream();

  // Set up http overrides. This is needed to increase the number of concurrent http requests allowed. This helps with the map tiles loading.
  HttpOverrides.global = MyHttpOverrides();

  // Load map tile cache
  var cacheDirectory = await getTemporaryDirectory();
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
        () => LocationAlarmState(),
        builder: (state) {

          // Check that everything is initialized before building the app. Right now, the only thing that needs to be initialized is the map tile cache and notification plugin.
          if (state.mapTileCacheStore == null || !state.notificationPluginIsInitialized) {
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
										// state.pageController.jumpToPage(index);
										state.pageController.animateToPage(index,	duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
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

// Notification stuff
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
int id = 0;

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

Future<void> checkAlarmsOnUserPositionChange() async {
  var state = June.getState(LocationAlarmState());

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

  var userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

  var triggeredAlarms = checkIfUserTriggersAlarms(userLatLng, activeAlarms);
  if (triggeredAlarms.isEmpty) {
    debugPrint('Alarm Check: No alarms triggered.');
    return;
  }

  for (var alarm in triggeredAlarms) debugPrint('Alarm Check: Triggered alarm ${alarm.name}');

  // If an alarm is already triggered, don't show another dialog.
  if (state.alarmIsCurrentlyTriggered) return;

  for (var alarm in triggeredAlarms) {
    if (state.notification) {
      // the notification boolean is always set to true but we might want to add user control later.
      debugPrint('Alarm Check: Sending the user a notification for alarm ${alarm.name}.');
      var notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentBanner: true, presentSound: true),
      );
      await flutterLocalNotificationsPlugin.show(id++, 'Alarm Triggered', 'You have entered the radius of alarm: ${alarm.name}.', notificationDetails);
    }

    if (state.vibration) {
      for (var i = 0; i < numberOfTriggeredAlarmVibrations; i++) {
        await Vibration.vibrate(duration: 1000);
        await Future<void>.delayed(Duration(milliseconds: 1000));
      }
    }

    // No alarm is currently triggered, so we can show the dialog.
    state.alarmIsCurrentlyTriggered = true;
    showAlarmDialog(NavigationService.navigatorKey.currentContext!, alarm.id);
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
