import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

const appName = 'Proximity Alarm';
const author = 'James Moreau';
const myEmail = 'jmorea03@uoguelph.ca';
const githubLink = 'www.github.com/jamesmoreau';

// const MapBoxTemplateUrl = 'https://api.mapbox.com/styles/v1/jamesm1/clraaajoh004t01piepmw4igo/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiamFtZXNtMSIsImEiOiJjbHJhYTc4NWYwYndiMmtqcXVoM2l4cGJ1In0.7dpOEpBRw55hQF8USd8Qrg';
const openStreetMapTemplateUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
// const mapboxurl = 'https://{s}.tiles.mapbox.com/v3/{id}/{z}/{x}/{y}.png';

const London = LatLng(51.5074, -0.1278);
const Toronto = LatLng(43.6532, -79.3832);
const Montreal = LatLng(45.5017, -73.5673);
const Dublin = LatLng(53.3498, -6.2603);
const Belfast = LatLng(54.5973, -5.9301);
const Edinburgh = LatLng(55.9533, -3.1883);

const initialZoom = 15.0;
const maxZoomSupported = 18.0;

const alarmBorderColor = Color(0xff2b2b2b);
const alarmBorderWidth = 2.0;
const alarmColorOpacity = 0.5;

const alarmCheckPeriod = Duration(seconds: 5);
const numberOfTriggeredAlarmVibrations = 6;

const sharedPreferencesAlarmKey = 'alarms';
const sharedPreferencesAlarmSoundKey = 'alarmSound';
const sharedPreferencesAlarmVibrationKey = 'alarmVibration';
const sharedPreferencesAlarmNotificationKey = 'alarmNotification';

ThemeData proximityAlarmTheme = ThemeData(
  // colorSchemeSeed: const Color(0xfff1f3e0),
  // colorSchemeSeed: Colors.lightBlue,
  // colorSchemeSeed: Color(0xffb2d2de),
  // colorSchemeSeed: Color.fromARGB(255, 201, 225, 233),

  colorScheme: scheme,

  // colorScheme: Airb
  // colorScheme: const ColorScheme(
  //     brightness: Brightness.light,
  // primary: Color(0xff2b2b2b),
  //     onPrimary: Colors.white,
  //     secondary: Colors.white,
  // onSecondary: Color(0xff2b2b2b),
  //     error: Colors.red,
  //     onError: Colors.white,
  //     // background: Color(0xffe6e6e6),
  //     background: Colors.white,
  //     onBackground: Color(0xff2b2b2b),
  // surface: Color(0xffe6e6e6),
  // onSurface: Color(0xff2b2b2b)),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.all(25),
    tileColor: Color.fromARGB(255, 234, 239, 246), // Background color of the ListTile
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  iconTheme: IconThemeData(color: Color(0xff50606e)),
);

ColorScheme scheme = ColorScheme(
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
  background: Color(0xfffcfcff),
  onBackground: Color(0xff1a1c1e),
  surface: Color(0xfffcfcff),
  onSurface: Color(0xff1a1c1e),
  surfaceVariant: Color(0xffdde3ea),
  onSurfaceVariant: Color(0xff41474d),
  outline: Color(0xff72787e),
  outlineVariant: Color(0xffc1c7ce),
  inverseSurface: Color(0xff2e3133),
  onInverseSurface: Color(0xfff0f0f3),
  inversePrimary: Color(0xff8dcdff),
  // primaryVariant: Color(0xff006493),
  // secondaryVariant: Color(0xff50606e),
  surfaceTint: Color(0xff006493),
);

const paleBlue = Color(0xffeaf0f5);
