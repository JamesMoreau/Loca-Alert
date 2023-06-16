import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/main.dart';

class ProxalarmState extends GetxController {
  ProxalarmView currentView = ProxalarmView.alarms;
  List<Alarm> alarms = <Alarm>[
    Alarm(name: 'First alarm', position: const LatLng(0, 0), radius: 10),
    Alarm(name: 'Second Alarm', position: LatLng(1, 1), radius: 20, color: Colors.blue),
    Alarm(name: 'Third Alarm', position: LatLng(2, 2), radius: 30, color: Colors.lightGreen),
    Alarm(name: 'Fourth Alarm', position: LatLng(3, 5), radius: 10, color: Colors.purple),
  ];
  MapController mapController = MapController();
}
