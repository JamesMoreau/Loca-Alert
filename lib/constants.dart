import 'package:flutter/material.dart';

const appName = "Proxalarm";
const author = "James Rush";
const myEmail = 'jmorea03@uoguelph.ca';
const githubLink = "www.github.com/jamesmoreau";

var proxalarmTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xfff1f3e0),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      tileColor: const Color(0xfff1f3e0), // Background color of the ListTile
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ));
