import 'package:fast_color_picker/fast_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';
import 'package:location_alarm/models/alarm.dart';
import 'package:location_alarm/views/map.dart';

class AlarmsView extends StatelessWidget {
  const AlarmsView({super.key});

  void openAlarmEdit(BuildContext context, Alarm alarm) {
    debugPrint('Editing alarm: ${alarm.name}, id: ${alarm.id}.');

    // Copy the alarm to the buffer alarm. We don't do this inside the edit widget because rebuilds will cause the buffer alarm to be reset.
    var state = June.getState(LocationAlarmState());
    state.bufferAlarm = createAlarm(name: alarm.name, position: alarm.position, radius: alarm.radius, color: alarm.color, active: alarm.active);
    state.nameInputController.text = alarm.name;

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
    return JuneBuilder(
      () => LocationAlarmState(),
      builder: (state) {
        if (state.alarms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No alarms.'),
                ElevatedButton(
                  child: Text('Add mock alarms'),
                  onPressed: () {
                    addAlarm(createAlarm(name: 'London', position: london, radius: 1000));
                    addAlarm(createAlarm(name: 'Dublin', position: dublin, radius: 2000, color: Colors.blue));
                    addAlarm(createAlarm(name: 'Toronto', position: toronto, radius: 3000, color: Colors.lightGreen));
                    addAlarm(createAlarm(name: 'Belfast', position: belfast, radius: 1000, color: Colors.purple));
                  },
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Scrollbar(
            child: ListView.builder(
              itemCount: state.alarms.length,
              itemBuilder: (context, index) {
                var alarm = state.alarms[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(alarm.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    leading: Icon(Icons.pin_drop_rounded, color: alarm.color, size: 30),
                    subtitle: Text(alarm.position.toSexagesimal(), style: TextStyle(fontSize: 9, color: Colors.grey[700])),
                    onLongPress: () => openAlarmEdit(context, alarm),
                    onTap: () => openAlarmEdit(context, alarm),
                    trailing: Switch(
                      value: alarm.active,
                      activeColor: alarm.color,
                      thumbIcon: thumbIcon,
                      onChanged: (value) {
                        var updatedAlarmData = createAlarm(name: alarm.name, position: alarm.position, radius: alarm.radius, color: alarm.color, active: value);
                        updateAlarmById(alarm.id, updatedAlarmData);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class EditAlarmDialog extends StatelessWidget {
  final String alarmId;

  const EditAlarmDialog({required this.alarmId, super.key});

  void saveBufferToAlarm() {
    var state = June.getState(LocationAlarmState());

    // Replace the actual alarm data with the buffer alarm.
    var alarm = getAlarmById(alarmId);
    if (alarm == null) {
      debugPrint('Error: Unable to save alarm changes.');
      return;
    }

    if (state.bufferAlarm == null) {
      debugPrint('Error: Buffer alarm is null.');
      return;
    }

    state.bufferAlarm!.name = state.nameInputController.text.trim();
    updateAlarmById(alarmId, state.bufferAlarm!);
  }

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      () => LocationAlarmState(),
      builder: (state) {
        if (state.bufferAlarm == null) {
          debugPrint('Error: Buffer alarm is null.');
          return const SizedBox();
        }

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
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                        resetEditAlarmState();
                      },
                    ),
                    Text(
                      'Edit Alarm',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      child: const Text('Save'),
                      onPressed: () {
                        saveBufferToAlarm();
                        Navigator.pop(context);
                        resetEditAlarmState();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text('Name', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                TextFormField(
                  textAlign: TextAlign.center,
                  controller: state.nameInputController,
                  onChanged: (value) => state.setState(),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear_rounded),
                      onPressed: () {
                        state.nameInputController.clear();
                        state.setState();
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
                    selectedColor: state.bufferAlarm!.color,
                    onColorSelected: (newColor) {
                      state.bufferAlarm!.color = newColor;
                      state.setState();
                    },
                  ),
                ),
                SizedBox(height: 30),
                Text('Position', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                Text(state.bufferAlarm!.position.toSexagesimal(), style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Needs to be async since we have to wait for navigateToAlarm to finish before we can reset the state.
                        Navigator.pop(context);
                        await navigateToAlarm(state.bufferAlarm!);
                        resetEditAlarmState();
                      },
                      icon: Icon(Icons.navigate_next_rounded),
                      label: Text('Go To Alarm'),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text('Radius / Size (in meters)', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                Text(state.bufferAlarm!.radius.toInt().toString(), style: TextStyle(fontWeight: FontWeight.bold)),
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
                        deleteAlarmById(alarmId);
                        Navigator.pop(context);
                        resetEditAlarmState();
                      },
                      child: Text('Delete Alarm', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void resetEditAlarmState() {
    var state = June.getState(LocationAlarmState());
    state.bufferAlarm = null;
    state.nameInputController.clear();
    state.setState();
  }
}

// for switch icons.
final MaterialStateProperty<Icon?> thumbIcon = MaterialStateProperty.resolveWith<Icon?>((states) {
  if (states.contains(MaterialState.selected)) return const Icon(Icons.check_rounded);

  return const Icon(Icons.close_rounded);
});
