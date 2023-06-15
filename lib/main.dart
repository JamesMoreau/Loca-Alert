import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/proxalarm_state.dart';

/* 
  TODO:
    add theme (material3)
    figure out pages (routes or enum or index ?)
    round navigation bar 
    simplify map options view
*/

enum Views { map, alarms }

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

enum View { alarms, map }

class HomeScreen extends StatelessWidget {
  final ProxalarmState ps = Get.put(ProxalarmState());

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: getView(ps.currentView.value),
        bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              ps.currentView.value = View.values[index];
            },
            selectedIndex: ps.currentView.value.index,
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

  Widget getView(View v) {
    switch (v) {
      case View.alarms:
        return Center(child: AlarmsView());
      case View.map:
        return FlutterMap(
          options: MapOptions(
            center: LatLng(51.509364, -0.128928),
            zoom: 9.2,
          ),
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
  final ProxalarmState ps = Get.find<ProxalarmState>();

  AlarmsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
          itemCount: ps.alarms.length,
          itemBuilder: (context, index) {
            var alarm = ps.alarms.elementAt(index);
            return ListTile(title: Text(alarm.name), trailing: Icon(Icons.pin_drop_rounded, color: alarm.color));
          }),
    );
  }
}
