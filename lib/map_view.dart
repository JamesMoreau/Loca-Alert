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
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(builder: (state) {
      var alarmPlacementIcon = state.isPlacingAlarm ? Icons.check : Icons.pin_drop_rounded;

      var statusBarHeight = MediaQuery.of(context).padding.top;

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

      if (state.isPlacingAlarm) {
        var alarmPlacementPosition = state.mapController.center;
        var alarmPlacementMarker = CircleMarker(point: alarmPlacementPosition, radius: state.alarmPlacementRadius, useRadiusInMeter: true);
        circles.add(alarmPlacementMarker);
      }

      return Stack(
        alignment: Alignment.center,
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
                      state.isPlacingAlarm = !(state.isPlacingAlarm);
                      state.update();
                    },
                    elevation: 4,
                    child: Icon(alarmPlacementIcon)),
              ],
            ),
          ),
          (state.isPlacingAlarm) // Display the slider only if we are placing an alarm
              ? Positioned(
                  bottom: 150,
                  child: Slider(
                    value: state.alarmPlacementRadius,
                    onChanged: (value) {
                      state.alarmPlacementRadius = value;
                      state.update();
                    },
                    min: 100,
                    max: 3000,
                    divisions: 100,
                  ))
              : SizedBox.shrink(),
        ],
      );
    });
  }
}

void placeNewAlarm() {
  ProxalarmState ps = Get.find<ProxalarmState>();

  // var center ps.mapController.center
}
