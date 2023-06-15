import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/proxalarm_state.dart';

/* 
  TODO:
    add theme (material3)
    round navigation bar 
    simplify map options view
*/

enum Views { map, alarms }

void main() {
  final ProxalarmState ps = Get.put(ProxalarmState());
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

enum View { alarms, map }

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(
      builder: (state) => Scaffold(
        body: getView(state.currentView, state),
        bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              state.currentView = View.values[index];
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
    );
  }

  Widget getView(View v, ProxalarmState state) {
    switch (v) {
      case View.alarms:
        return Center(child: AlarmsView());
      case View.map:
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
  }
}

class AlarmsView extends StatelessWidget {
  AlarmsView({super.key});

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
                leading: Icon(Icons.pin_drop_rounded, color: alarm.color),
                trailing: Switch(
                  value: alarm.active,
                  onChanged: (value) {
                    print('alarm.active is ${alarm.active}. value is $value');
                    alarm.active = value;
                    print('alarm.active is now ${alarm.active}');
                    state.update();
                  },
                ),
              ),
            );
          });
    });
  }
}
