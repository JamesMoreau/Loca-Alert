import 'package:flutter_map/plugin_api.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/main.dart';

class ProxalarmState extends GetxController {
  View currentView = View.alarms;
  List<Alarm> alarms = <Alarm>[Alarm(name: "First alarm", position: const LatLng(0, 0), radius: 10.0)];
  MapController mapController = MapController();
}
