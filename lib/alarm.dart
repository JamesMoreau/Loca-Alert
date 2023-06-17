import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/proxalarm_state.dart';

class Alarm {
  String id = '';
  String name = '';
  Color color = Colors.redAccent;
  LatLng position = LatLng(0, 0);
  double radius = 0; // in meters
  bool active = true;
}

Alarm createAlarm({required String name, required LatLng position, required double radius, Color? color, bool? active}) {
  Alarm alarm = Alarm();
  alarm.id = idGenerator.v1();
  alarm.name = name;
  alarm.color = color ?? Colors.redAccent;
  alarm.position = position;
  alarm.radius = radius;
  alarm.active = active ?? true;
  return alarm;
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
  return createAlarm(
    name: alarmJson['name'],
    color: Color(alarmJson['color']),
    position: LatLng(alarmJson['position']['latitude'], alarmJson['position']['longitude']),
    radius: alarmJson['radius'],
  );
}

//This function returns the alarms that the user's position is currently intersected with.
List<Alarm> checkIfUserTriggersAlarms() {
  return [];
}
