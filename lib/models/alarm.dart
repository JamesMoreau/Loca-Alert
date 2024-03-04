import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:loca_alert/constants.dart';
import 'package:loca_alert/loca_alert_state.dart';

class Alarm {
	String id;
	String name;
	Color color;
	LatLng position;
	double radius; // Meters
	bool active;

  Alarm({
    required this.name, 
    required this.position, 
    required this.radius, 
    String? id, 
    Color? color, 
    this.active = true,
  }) : assert(radius > 0),
       id = id ?? idGenerator.v1(),
       color = color ?? availableAlarmColors.redAccent;
}

Map<String, dynamic> alarmToMap(Alarm alarm) {
	return {
    'id': alarm.id,
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

Alarm alarmFromMap(Map<String, dynamic> alarmJson) {
	return Alarm(
    id: alarmJson['id'] as String,
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
		var distance = Geolocator.distanceBetween(alarm.position.latitude, alarm.position.longitude, userPosition.latitude, userPosition.longitude);
		if (distance <= alarm.radius) triggeredAlarms.add(alarm);
	}

	return triggeredAlarms;
}

Alarm? getClosestAlarmToPosition(LatLng position, List<Alarm> alarms) {
	Alarm? closestAlarm;
	var closestDistance = double.infinity;

	if (alarms.isEmpty) return null;

	for (var alarm in alarms) {
		var distance = Geolocator.distanceBetween(alarm.position.latitude, alarm.position.longitude, position.latitude, position.longitude);
		if (distance < closestDistance) {
			closestAlarm = alarm;
			closestDistance = distance;
		}
	}

	return closestAlarm;
}
