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
    Show alarms on map
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
