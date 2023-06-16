import 'package:flutter/material.dart';

const appName = "Proxalarm";
const author = "James Rush";
const myEmail = 'jmorea03@uoguelph.ca';
const githubLink = "www.github.com/jamesmoreau";

var proxalarmTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xfff1f3e0),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.all(25),
    tileColor: const Color(0xfff1f3e0), // Background color of the ListTile
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
  // switchTheme: SwitchThemeData(
  //   trackColor: MaterialStateProperty.all<Color>(Colors.grey), // Set the track color
  //   thumbColor: MaterialStateProperty.all<Color>(Colors.blue), // Set the thumb color
  //   overlayColor: MaterialStateProperty.all<Color>(Colors.blue.withOpacity(0.4)), // Set the overlay color
  //   splashRadius: 16.0, // Set the splash radius
  // ),
);
