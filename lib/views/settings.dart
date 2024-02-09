import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';

class SettingsView extends StatelessWidget {
	const SettingsView({super.key});

	@override
	Widget build(BuildContext context) {
		return GetBuilder<ProximityAlarmState>(
			builder: (state) {
				return SafeArea(
					child: ListView(
						padding: EdgeInsets.all(16),
						children: [
							/*Padding(
								padding: const EdgeInsets.symmetric(vertical: 8),
								child: SwitchListTile(
									title: Text('Alarm Notification'),
									value: state.notification,
									onChanged: (value) {
										changeAlarmNotification(newValue: value);
									},
									thumbIcon: thumbIcon,
								),
							),*/
							Padding(
								padding: const EdgeInsets.symmetric(vertical: 8),
								child: SwitchListTile(
									title: Text('Alarm Sound'),
									value: state.alarmSound,
									onChanged: (value) {
										changeAlarmSound(newValue: value);
									},
									thumbIcon: thumbIcon,
								),
							),
							Padding(
								padding: const EdgeInsets.symmetric(vertical: 8),
								child: SwitchListTile(
									title: Text('Vibration'),
									value: state.vibration,
									onChanged: (value) {
										changeVibration(newValue: value);
									},
									thumbIcon: thumbIcon,
								),
							),
							Padding(
								padding: const EdgeInsets.symmetric(vertical: 8),
								child: SwitchListTile(
									title: Text('Show Closest Off-Screen Alarm'),
									value: state.showClosestOffScreenAlarm,
									onChanged: (value) {
										changeShowClosestOffScreenAlarm(newValue: value);
									},
									thumbIcon: thumbIcon,
								),
							),
							Padding(
								padding: const EdgeInsets.symmetric(vertical: 8),
								child: ListTile(
									title: Text('Location Settings'),
									trailing: Icon(Icons.keyboard_arrow_right),
									onTap: Geolocator.openLocationSettings,
								),
							),
							if (kDebugMode)
								Padding(
									padding: const EdgeInsets.symmetric(vertical: 8),
									child: ListTile(
										title: Text('Print Alarms SP Data.'),
										trailing: Icon(Icons.alarm_rounded),
										onTap: () async {
											var box = Hive.box<List<String>>(alarmsHiveBox);
											var alarmJsonStrings = box.get(alarmsKey);
											if (alarmJsonStrings == null) {
												debugPrint('No alarms found in shared preferences.');
												return;
											}

											for (var alarmJsonString in alarmJsonStrings) {
												debugPrint(alarmJsonString);
											}
										},
									),
								),
						],
					),
				);
			},
		);
	}
}

// for switch icons.
final MaterialStateProperty<Icon?> thumbIcon = MaterialStateProperty.resolveWith<Icon?>((states) {
	if (states.contains(MaterialState.selected)) return const Icon(Icons.check_rounded);

	return const Icon(Icons.close_rounded);
});
