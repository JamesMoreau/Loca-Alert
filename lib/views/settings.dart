import 'dart:io';

import 'package:feedback/feedback.dart';
import 'package:feedback_sentry/feedback_sentry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:geolocator/geolocator.dart';
import 'package:june/june.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';
import 'package:path_provider/path_provider.dart';

class SettingsView extends StatelessWidget {
	const SettingsView({super.key});

	@override
	Widget build(BuildContext context) {
		return JuneBuilder(
      () => LocationAlarmState(),
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
							Padding(
								padding: const EdgeInsets.symmetric(vertical: 8),
								child: ListTile(
									title: Text('Give Feedback'),
									trailing: Icon(Icons.feedback_rounded),
									onTap: () {
										BetterFeedback.of(context).show(sendFeedback);
									},
								),
							),
							if (kDebugMode)
								Padding(
									padding: const EdgeInsets.symmetric(vertical: 8),
									child: ListTile(
										title: Text('Print Alarms In Storage.'),
										trailing: Icon(Icons.alarm_rounded),
										onTap: () async {
											var directory = await getApplicationDocumentsDirectory();
											var alarmsPath = '${directory.path}${Platform.pathSeparator}$alarmsFilename';
											var alarmsFile = File(alarmsPath);

											if (!alarmsFile.existsSync()) {
												debugPrint('Warning: No alarms file found in storage.');
												return;
											}

											var alarmJsons = await alarmsFile.readAsString();
											if (alarmJsons.isEmpty) {
												debugPrint('No alarms found in storage.');
												return;
											}

											debugPrint('Alarms found in storage: $alarmJsons');
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

Future<void> sendFeedback(UserFeedback feedback) async {
	// Save the feedback screenshot to the user's device.
	var dir = await getTemporaryDirectory();
	var targetPath = '${dir.path}/feedback_image.png';
	var imageFile = File(targetPath);
	await imageFile.writeAsBytes(feedback.screenshot);

	// Create and send the email.
	var email = Email(
		body: 'Feedback Text: $feedback.text',
		subject: 'Location Alarm Feedback',
		recipients: [myEmail],
		attachmentPaths: [imageFile.path],
	);

	await FlutterEmailSender.send(email);
}

// for switch icons.
final MaterialStateProperty<Icon?> thumbIcon = MaterialStateProperty.resolveWith<Icon?>((states) {
	if (states.contains(MaterialState.selected)) return const Icon(Icons.check_rounded);
	return const Icon(Icons.close_rounded);
});
