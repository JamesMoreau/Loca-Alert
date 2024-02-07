import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';
import 'package:vibration/vibration.dart';

void showAlarmDialog(BuildContext context, String alarmId) {
	var las = Get.find<ProximityAlarmState>();
	var alarm = getAlarmById(alarmId);

	if (alarm == null) {
		debugPrint('Error: Unable to retrieve triggered alarm.');
		las.alarmIsCurrentlyTriggered = false;
		return;
	}

	// Callback when the user presses the "Dismiss" button or alarm times out.
	void deactivateAlarmAndCloseDialog(BuildContext context) {
		var dismissedAlarm = createAlarm(
			name: alarm.name,
			position: alarm.position,
			radius: alarm.radius,
			color: alarm.color,
			active: false, // deactivate the alarm
		);
		updateAlarmById(alarmId, dismissedAlarm);
		if (las.vibration) Vibration.cancel();
		Navigator.pop(context);
		las.alarmIsCurrentlyTriggered = false;
	}

	showGeneralDialog<void>(
		context: context,
		pageBuilder: (context, a1, a2) => Dialog.fullscreen(
			child: Container(
				width: MediaQuery.of(context).size.width,
				height: MediaQuery.of(context).size.height,
				color: paleBlue,
				padding: EdgeInsets.all(20),
				child: SafeArea(
					child: Column(
						children: [
							Expanded(
								flex: 3,
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Text(
											'Alarm Triggered',
											style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
										),
										SizedBox(height: 16),
										Text(
											'You have entered the radius of an alarm.',
											textAlign: TextAlign.center,
											style: TextStyle(
												fontSize: 20,
												fontWeight: FontWeight.w300,
											),
										),
										SizedBox(height: 16),
										Icon(Icons.alarm, size: 100, color: alarm.color),
									],
								),
							),
							Expanded(
								flex: 2,
								child: Column(
									children: [
										Text(alarm.name, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
										SizedBox(height: 16),
										ElevatedButton(
											onPressed: () => deactivateAlarmAndCloseDialog(context),
											style: ElevatedButton.styleFrom(
												backgroundColor: Colors.blueGrey,
												foregroundColor: Colors.white,
												minimumSize: Size(225, 70),
												textStyle: TextStyle(fontSize: 25),
											),
											child: Text('Dismiss'),
										),
									],
								),
							),
						],
					),
				),
			),
		),
	);
}
