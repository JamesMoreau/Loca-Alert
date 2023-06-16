import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/proxalarm_state.dart';
import 'package:url_launcher/url_launcher.dart';

/* 
  TODO:
    short term:
    Edit alarm ui pull up / delete alarm
    save alarms to file
    place alarm manually (ui plus icon at the top)
    settings: alarm sound, vibration?, location settings
    show user's current location on map.

    long term:
    switch map tile provider (mapbox, thunderforest, etc)
    checkout mapbox: https://docs.fleaflet.dev/tile-servers/using-mapbox
    go alarm on map. using MapController
    tile chaching
    go to user location on map if offscreen.
    show some sort icon on map for alarm if too zoomed out to see the circle. (could use current zoom level to determine this).
    Logo
    show something when user is too zoomed in. Use current zoom level to determine this.
    get distance to closest alarm. have some sort of ui layer that points towards the alarm from current location if it is offscreen.
*/

enum Views { map, alarms }

void main() {
  final ProxalarmState ps = Get.put(ProxalarmState()); // Inject the global app state into memory.
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      theme: proxalarmTheme,
    );
  }
}

enum ProxalarmView { alarms, map }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(
      builder: (state) => Scaffold(
        body: getView(state.currentView, state),
        extendBody: true,
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          child: NavigationBar(
              onDestinationSelected: (int index) {
                state.currentView = ProxalarmView.values[index];
                state.update();
              },
              selectedIndex: state.currentView.index,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.pin_drop_rounded),
                  label: 'Alarms',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
              ]),
        ),
      ),
    );
  }

  Widget getView(ProxalarmView v, ProxalarmState state) {
    switch (v) {
      case ProxalarmView.alarms:
        return AlarmsView();
      case ProxalarmView.map:
        return MapView();
    }
  }
}

class MapView extends StatelessWidget {
  const MapView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(builder: (state) {
      var circles = <CircleMarker>[];
      for (var alarm in state.alarms) {
        var marker = CircleMarker(
            point: alarm.position,
            color: alarm.color.withOpacity(alarmColorOpacity),
            borderColor: alarmBorderColor,
            borderStrokeWidth: alarmBorderWidth,
            radius: alarm.radius,
            useRadiusInMeter: true);
        circles.add(marker);
      }

      return FlutterMap(
        mapController: state.mapController,
        options: MapOptions(center: LatLng(51.509364, -0.128928), zoom: 9.2, interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          CircleLayer(circles: circles),
        ],
      );
    });
  }
}

class AlarmsView extends StatelessWidget {
  const AlarmsView({super.key});

  void openAlarmEdit(BuildContext context, Alarm alarm) {
    debugPrint('Editing alarm ${alarm.name}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EditAlarmDialog(alarmId: alarm.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(builder: (state) {
      return ListView.builder(
          itemCount: state.alarms.length,
          itemBuilder: (context, index) {
            var alarm = state.alarms[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(alarm.name),
                leading: Icon(Icons.pin_drop_rounded, color: alarm.color, size: 30),
                subtitle: Text(alarm.position.toSexagesimal(), style: TextStyle(fontSize: 9, color: Colors.grey[700])),
                enabled: alarm.active,
                onLongPress: () => openAlarmEdit(context, alarm),
                onTap: () => openAlarmEdit(context, alarm),
                trailing: Switch(
                  value: alarm.active,
                  activeColor: alarm.color,
                  onChanged: (value) {
                    alarm.active = value;
                    state.update();
                  },
                ),
              ),
            );
          });
    });
  }
}

class EditAlarmDialog extends StatefulWidget {
  final String alarmId;

  const EditAlarmDialog({super.key, required this.alarmId});

  @override
  State<EditAlarmDialog> createState() => _EditAlarmDialogState();
}

class _EditAlarmDialogState extends State<EditAlarmDialog> {
  Alarm? bufferAlarm;

  @override
  void initState() {
    bufferAlarm = getAlarmById(widget.alarmId);
    super.initState();
  }

  void saveBufferAlarm() {
    // Needs to replace the actual alarm with buffer
  }

  @override
  Widget build(BuildContext context) {
    if (bufferAlarm == null) {
      return Text('Error: Unable to retrieve alarm');
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                Text(
                  'Edit Alarm',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    saveBufferAlarm();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 16.0),
            TextFormField(
              initialValue: bufferAlarm!.name,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
              onChanged: (value) {
                bufferAlarm!.name = value;
              },
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
