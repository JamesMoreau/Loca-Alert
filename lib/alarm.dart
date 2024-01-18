import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/location_alarm_state.dart';

class Alarm {
  String id = '';
  String name = '';
  Color color = Colors.redAccent;
  LatLng position = LatLng(0, 0);
  double radius = 0; // Meters
  bool active = true;
}

Alarm createAlarm({required String name, required LatLng position, required double radius, Color? color, bool? active}) {
  var alarm = Alarm();
  alarm.id = idGenerator.v1(); // time-based unique id
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
    'active': alarm.active,
  };
}

Alarm alarmFromJson(Map<String, dynamic> alarmJson) {
  return createAlarm(
    name: alarmJson['name'] as String,
    color: Color(alarmJson['color'] as int),
    position: LatLng(
      (alarmJson['position'] as Map<String, dynamic>)['latitude'] as double,
      (alarmJson['position'] as Map<String, dynamic>)['longitude'] as double,
    ),
    radius: alarmJson['radius'] as double,
    active: alarmJson['active'] as bool,
  );
}

// This function returns the alarms that the user's position is currently intersected with.
List<Alarm> checkIfUserTriggersAlarms(LatLng userPosition, List<Alarm> alarms) {
  var triggeredAlarms = <Alarm>[];

  for (var alarm in alarms) {
    // var distance = Distance().as(LengthUnit.Meter, userPosition, alarm.position);
    var distance = Geolocator.distanceBetween(alarm.position.latitude, alarm.position.longitude, userPosition.latitude, userPosition.longitude);
    if (distance <= alarm.radius) triggeredAlarms.add(alarm);
  }

  return triggeredAlarms;
}
