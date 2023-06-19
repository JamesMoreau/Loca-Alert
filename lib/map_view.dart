import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/proxalarm_state.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool isPlacingAlarm = false;

  @override
  Widget build(BuildContext context) {
    var statusBarHeight = MediaQuery.of(context).padding.top;
    var alarmPlacementIcon = isPlacingAlarm ? Icons.check : Icons.pin_drop_rounded;

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

      return Stack(
        children: [
          FlutterMap(
            // Map
            mapController: state.mapController,
            options: MapOptions(
                center: LatLng(51.509364, -0.128928),
                zoom: initialZoom,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                maxZoom: maxZoomSupported),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              CircleLayer(circles: circles),
            ],
          ),
          Positioned(
            top: statusBarHeight + 10,
            right: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(onPressed: () {}, elevation: 4, child: Icon(Icons.my_location_rounded)),
                SizedBox(height: 10),
                FloatingActionButton(
                    onPressed: () {
                      isPlacingAlarm = !isPlacingAlarm;
                      setState(() {});
                    },
                    elevation: 4,
                    child: Icon(alarmPlacementIcon)),
              ],
            ),
          ),
        ],
      );
    });
  }
}

void placeNewAlarm() {
  ProxalarmState ps = Get.find<ProxalarmState>();

  // var center ps.mapController.center
}
