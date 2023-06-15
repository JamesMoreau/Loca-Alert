import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

class Alarm {
  String name;
  Color color;
  LatLng position;
  double radius;
  bool active;

  Alarm({required this.name, required this.position, required this.radius, this.color = Colors.redAccent, this.active = true});
}

Map<String, dynamic> alarmToJson(Alarm alarm) {
  return {
    'name': alarm.name,
    'color': alarm.color.value,
    'position': {
      'latitude': alarm.position.latitude,
      'longitude': alarm.position.longitude,
    },
    'radius': alarm.radius,
  };
}

Alarm alarmFromJson(Map<String, dynamic> alarmJson) {
  return Alarm(
    name: alarmJson['name'],
    color: Color(alarmJson['color']),
    position: LatLng(alarmJson['position']['latitude'], alarmJson['position']['longitude']),
    radius: alarmJson['radius'],
  );
}
