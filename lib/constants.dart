import 'dart:io';

import 'package:flutter/foundation.dart';
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

const settingsAlarmVibrationKey = 'alarmVibration';
const settingsAlarmNotificationKey = 'alarmNotification';
const settingsShowClosestOffScreenAlarmKey = 'showClosestOffScreenAlarm';
const settingsFilename = 'settings.json';
const alarmsFilename = 'alarms.json';

class AvailableAlarmColors {
  static const Color blue = Colors.blue;
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
  static const Color redAccent = Colors.redAccent;
  static const Color purple = Colors.purple;
  static const Color pink = Colors.pink;
  static const Color teal = Colors.teal;
  static const Color brown = Colors.brown;
  static const Color indigo = Colors.indigo;
  static const Color amber = Colors.amber;
  static const Color grey = Colors.grey;
  static const Color black = Colors.black;

  static final Map<String, Color> allColors = {
    'blue': blue,
    'green': green,
    'orange': orange,
    'redAccent': redAccent,
    'purple': purple,
    'pink': pink,
    'teal': teal,
    'brown': brown,
    'indigo': indigo,
    'amber': amber,
    'grey': grey,
    'black': black,
  };

  // Method to get a color by its name
  static Color? getColorByName(String name) {
    return allColors[name];
  }
}

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
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff006493),
    onPrimary: Colors.white,
    primaryContainer: Color.fromARGB(255, 216, 237, 255),
    onPrimaryContainer: Color(0xff001e30),
    secondary: Color(0xff50606e),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffd3e5f5),
    onSecondaryContainer: Color(0xff0c1d29),
    tertiary: Color(0xff65587b),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xffebddff),
    onTertiaryContainer: Color(0xff201634),
    error: Color(0xffba1a1a),
    onError: Colors.white,
    errorContainer: Color(0xffffdad6),
    onErrorContainer: Color(0xff410002),
    surface: Color(0xfffcfcff),
    onSurface: Color(0xff1a1c1e),
    surfaceContainerHighest: Color(0xffdde3ea),
    onSurfaceVariant: Color(0xff41474d),
    outline: Color(0xff72787e),
    outlineVariant: Color(0xffc1c7ce),
    inverseSurface: Color(0xff2e3133),
    onInverseSurface: Color(0xfff0f0f3),
    inversePrimary: Color(0xff8dcdff),
    surfaceTint: Color(0xff006493),
  ),
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

const paleBlue = Color(0xffeaf0f5);

void debugPrintInfo(String message) {
  if (kDebugMode) debugPrint(message);
}

void debugPrintWarning(String message) => debugPrintInfo('📙 $message');
void debugPrintError(String message) => debugPrintInfo('📕 $message');
void debugPrintSuccess(String message) => debugPrintInfo('📗 $message');

// for switch icons.
final WidgetStateProperty<Icon?> thumbIcon = WidgetStateProperty.resolveWith<Icon?>((states) {
  if (states.contains(WidgetState.selected)) return const Icon(Icons.check_rounded);
  return const Icon(Icons.close_rounded);
});
