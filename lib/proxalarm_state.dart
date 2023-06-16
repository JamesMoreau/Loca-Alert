import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/main.dart';

class ProxalarmState extends GetxController {
  ProxalarmView currentView = ProxalarmView.alarms;
  List<Alarm> alarms = <Alarm>[
    Alarm(name: 'London', position: London, radius: 1000),
    Alarm(name: 'Dublin', position: Dublin, radius: 2000, color: Colors.blue),
    Alarm(name: 'Toronto', position: Toronto, radius: 3000, color: Colors.lightGreen),
    Alarm(name: 'Belfast', position: Belfast, radius: 1000, color: Colors.purple),
  ];
  MapController mapController = MapController();
}
