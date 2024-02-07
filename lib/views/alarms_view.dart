import 'package:fast_color_picker/fast_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';

class AlarmsView extends StatelessWidget {
	const AlarmsView({super.key});

	void openAlarmEdit(BuildContext context, Alarm alarm) {
		debugPrint('Editing alarm: ${alarm.name}, id: ${alarm.id}.');
		showModalBottomSheet<void>(
			context: context,
			isScrollControlled: true,
			builder: (context) {
				return EditAlarmDialog(alarmId: alarm.id);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return GetBuilder<ProximityAlarmState>(
			builder: (state) {
				if (state.alarms.isEmpty) {
					return Center(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								Text('No alarms.'),
								if (kDebugMode)
									ElevatedButton(
										child: Text('Add mock alarms'),
										onPressed: () {
											addAlarm(createAlarm(name: 'London', position: London, radius: 1000));
											addAlarm(createAlarm(name: 'Dublin', position: Dublin, radius: 2000, color: Colors.blue));
											addAlarm(createAlarm(name: 'Toronto', position: Toronto, radius: 3000, color: Colors.lightGreen));
											addAlarm(createAlarm(name: 'Belfast', position: Belfast, radius: 1000, color: Colors.purple));
										},
									),
							],
						),
					);
				}

				return ListView.builder(
					itemCount: state.alarms.length,
					itemBuilder: (context, index) {
						var alarm = state.alarms[index];
						return Padding(
							padding: const EdgeInsets.all(8),
							child: ListTile(
								title: Text(alarm.name),
								leading: Icon(Icons.pin_drop_rounded, color: alarm.color, size: 30),
								subtitle: Text(alarm.position.toSexagesimal(), style: TextStyle(fontSize: 9, color: Colors.grey[700])),
								onLongPress: () => openAlarmEdit(context, alarm),
								onTap: () => openAlarmEdit(context, alarm),
								trailing: Switch(
									value: alarm.active,
									activeColor: alarm.color,
									thumbIcon: thumbIcon,
									onChanged: (value) {
										// alarm.active = value;
										var updatedAlarmData =
												createAlarm(name: alarm.name, position: alarm.position, radius: alarm.radius, color: alarm.color, active: value);
										updateAlarmById(alarm.id, updatedAlarmData);
									},
								),
							),
						);
					},
				);
			},
		);
	}
}

class EditAlarmDialog extends StatefulWidget {
	final String alarmId;

	const EditAlarmDialog({required this.alarmId, super.key});

	@override
	State<EditAlarmDialog> createState() => _EditAlarmDialogState();
}

class _EditAlarmDialogState extends State<EditAlarmDialog> {
	ProximityAlarmState pas = Get.find<ProximityAlarmState>();
	late TextEditingController nameInputController;
	late Alarm bufferAlarm;

	@override
	void initState() {
		var alarm = getAlarmById(widget.alarmId);
		if (alarm == null) {
			debugPrint('Error: Unable to retrieve alarm.');
			return;
		}

		bufferAlarm = createAlarm(name: alarm.name, position: alarm.position, radius: alarm.radius, color: alarm.color, active: alarm.active);

		nameInputController = TextEditingController(text: bufferAlarm.name);

		super.initState();
	}

	@override
	void dispose() {
		nameInputController.dispose();
		super.dispose();
	}

	void saveBufferToAlarm() {
		// Replace the actual alarm data with the buffer alarm.
		var alarm = getAlarmById(widget.alarmId);
		if (alarm == null) {
			debugPrint('Error: Unable to save alarm changes.');
			return;
		}

		bufferAlarm.name = nameInputController.text.trim();
		updateAlarmById(widget.alarmId, bufferAlarm);
	}

	@override
	Widget build(BuildContext context) {
		// if (bufferAlarm == null) {
		//   return Text('Error: Unable to retrieve alarm');
		// }

		return SizedBox(
			height: MediaQuery.of(context).size.height * 0.9,
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					mainAxisSize: MainAxisSize.min,
					children: [
						Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
								Text(
									'Edit Alarm',
									style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
								),
								TextButton(
									child: const Text('Save'),
									onPressed: () {
										saveBufferToAlarm();
										Navigator.pop(context);
									},
								),
							],
						),
						SizedBox(height: 30),
						Text('Name', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
						TextFormField(
							textAlign: TextAlign.center,
							controller: nameInputController,
							decoration: InputDecoration(
								suffixIcon: IconButton(
									icon: Icon(Icons.clear_rounded),
									onPressed: () {
										nameInputController.clear();
										setState(() {});
									},
								),
							),
						),
						SizedBox(height: 30),
						Text('Color', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
						SingleChildScrollView(
							scrollDirection: Axis.horizontal,
							child: FastColorPicker(
								icon: Icons.pin_drop_rounded,
								selectedColor: bufferAlarm.color,
								onColorSelected: (newColor) => setState(() => bufferAlarm.color = newColor),
							),
						),
						SizedBox(height: 30),
						Text('Position', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
						Text(bufferAlarm.position.toSexagesimal(), style: TextStyle(fontWeight: FontWeight.bold)),
						SizedBox(height: 10),
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								ElevatedButton.icon(
									onPressed: () {
										Navigator.of(context).pop();
										navigateToAlarm(bufferAlarm);
									},
									icon: Icon(Icons.navigate_next_rounded),
									label: Text('Go To Alarm'),
								),
							],
						),
						SizedBox(height: 30),
						Text('Radius / Size (in meters)', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
						Text(bufferAlarm.radius.toInt().toString(), style: TextStyle(fontWeight: FontWeight.bold)),
						SizedBox(height: 30),
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								ElevatedButton(
									style: ElevatedButton.styleFrom(
										elevation: 0,
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(8),
											side: BorderSide(color: Colors.redAccent, width: 2),
										),
									),
									onPressed: () {
										deleteAlarmById(widget.alarmId);
										Navigator.of(context).pop();
									},
									child: Text('Delete Alarm', style: TextStyle(color: Colors.redAccent)),
								),
							],
						),
					],
				),
			),
		);
	}
}

// for switch icons.
final MaterialStateProperty<Icon?> thumbIcon = MaterialStateProperty.resolveWith<Icon?>((states) {
	if (states.contains(MaterialState.selected)) return const Icon(Icons.check_rounded);

	return const Icon(Icons.close_rounded);
});
