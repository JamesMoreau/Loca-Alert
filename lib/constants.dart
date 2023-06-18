// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

const appName = "Proxalarm";
const author = "James Rush";
const myEmail = 'jmorea03@uoguelph.ca';
const githubLink = "www.github.com/jamesmoreau";

const London = LatLng(51.5074, -0.1278);
const Toronto = LatLng(43.6532, -79.3832);
const Montreal = LatLng(45.5017, -73.5673);
const Dublin = LatLng(53.3498, -6.2603);
const Belfast = LatLng(54.5973, -5.9301);
const Edinburgh = LatLng(55.9533, -3.1883);

const initialZoom = 9.0;
const maxZoomSupported = 18.0;

const alarmBorderColor = Color(0xff2b2b2b);
const alarmBorderWidth = 2.0;
const alarmColorOpacity = 0.5;

const sharedPreferencesAlarmKey = 'alarms';

var proxalarmTheme = ThemeData(
  useMaterial3: true,
  // colorSchemeSeed: const Color(0xfff1f3e0),
  colorSchemeSeed: Colors.lightBlue,
  // colorSchemeSeed: Color(0xffb2d2de),
  // colorSchemeSeed: Color.fromARGB(255, 201, 225, 233),

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
        tileColor: Color.fromARGB(255, 229, 240, 255), // Background color of the ListTile
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
);
