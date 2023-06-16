import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/proxalarm_state.dart';

/* 
  TODO:
    checkout mapbox: https://docs.fleaflet.dev/tile-servers/using-mapbox
    add settings: alarm sound, vibration?, location settings
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
        return Center(child: AlarmsView());
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
    return GetBuilder<ProxalarmState>(
      builder: (state) {
        return FlutterMap(
          mapController: state.mapController,
          options: MapOptions(center: LatLng(51.509364, -0.128928), zoom: 9.2, interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
          ],
        );
      }
    );
  }
}

class AlarmsView extends StatelessWidget {
  const AlarmsView({super.key});

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
