import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';

const author = 'James Moreau';
const myEmail = 'jp.moreau@aol.com';
const githubLink = 'www.github.com/jamesmoreau';
const appleID = '6478944468';

const openStreetMapTemplateUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const mapTileCacheFilename = 'myMapTiles';

const initialZoom = 15.0;
const circleToMarkerZoomThreshold = 10.0;
const maxZoomSupported = 18.0;

const alarmCheckPeriod = Duration(seconds: 5);
const numberOfTriggeredAlarmVibrations = 6;

const settingsAlarmVibrationKey            = 'alarmVibration';
const settingsAlarmNotificationKey         = 'alarmNotification';
const settingsShowClosestOffScreenAlarmKey = 'showClosestOffScreenAlarm';
const settingsFilename                     = 'settings.json';
const alarmsFilename                       = 'alarms.json';

const availableAlarmColors = (
  blue:      Colors.blue,
  green:     Colors.green,
  orange:    Colors.orange,
  redAccent: Colors.redAccent,
  purple:    Colors.purple,
  pink:      Colors.pink,
  teal:      Colors.teal,
  brown:     Colors.brown,
  indigo:    Colors.indigo,
  amber:     Colors.amber,
  grey:      Colors.grey,
  black:     Colors.black
);

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

ThemeData locationAlarmTheme = ThemeData(
	colorScheme: scheme,
	listTileTheme: ListTileThemeData(
		contentPadding: const EdgeInsets.all(25),
		tileColor: const Color.fromARGB(255, 234, 239, 246), // Background color of the ListTile
		shape: RoundedRectangleBorder(
			borderRadius: BorderRadius.circular(8),
		),
	),
	sliderTheme: const SliderThemeData(
		thumbShape: RoundSliderThumbShape(enabledThumbRadius: 13),
	),
	iconTheme: const IconThemeData(color: Color(0xff50606e)),
);

ColorScheme scheme = const ColorScheme(
	brightness:           Brightness.light,
	primary:              Color(0xff006493),
	onPrimary:            Colors.white,
	primaryContainer:     Color.fromARGB(255, 216, 237, 255),
	onPrimaryContainer:   Color(0xff001e30),
	secondary:            Color(0xff50606e),
	onSecondary:          Color(0xffffffff),
	secondaryContainer:   Color(0xffd3e5f5),
	onSecondaryContainer: Color(0xff0c1d29),
	tertiary:             Color(0xff65587b),
	onTertiary:           Color(0xffffffff),
	tertiaryContainer:    Color(0xffebddff),
	onTertiaryContainer:  Color(0xff201634),
	error:                Color(0xffba1a1a),
	onError:              Colors.white,
	errorContainer:       Color(0xffffdad6),
	onErrorContainer:     Color(0xff410002),
	background:           Color(0xfffcfcff),
	onBackground:         Color(0xff1a1c1e),
	surface:              Color(0xfffcfcff),
	onSurface:            Color(0xff1a1c1e),
	surfaceVariant:       Color(0xffdde3ea),
	onSurfaceVariant:     Color(0xff41474d),
	outline:              Color(0xff72787e),
	outlineVariant:       Color(0xffc1c7ce),
	inverseSurface:       Color(0xff2e3133),
	onInverseSurface:     Color(0xfff0f0f3),
	inversePrimary:       Color(0xff8dcdff),
	surfaceTint:          Color(0xff006493),
);

const paleBlue = Color(0xffeaf0f5);

void debugPrintWarning(String message) => debugPrint('📙: $message');

void debugPrintError(String message) => debugPrint('📕: $message');

void debugPrintSuccess(String message) => debugPrint('📗: $message');

// Calculates the distance between two points on the Earth's surface using the Haversine formula.
double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
  var earthRadius = 6378137.0;
  var dLat = toRadians(endLatitude - startLatitude);
  var dLon = toRadians(endLongitude - startLongitude);

  var a = pow(sin(dLat / 2), 2) +
          pow(sin(dLon / 2), 2) *
          cos(toRadians(startLatitude)) *
          cos(toRadians(endLatitude));
  var c = 2 * asin(sqrt(a));

  return earthRadius * c;
}

double toRadians(double degree) {
  return degree * pi / 180;
}
