import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/alarm.dart';
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

      // Place all the alarms on the map.
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

      // Placing alarm UI
      if (state.isPlacingAlarm) {
        var alarmPlacementPosition = state.mapController.center;
        var alarmPlacementMarker = CircleMarker(
            point: alarmPlacementPosition,
            radius: state.alarmPlacementRadius,
            color: Colors.redAccent.withOpacity(0.5),
            borderColor: Colors.black,
            borderStrokeWidth: 2,
            useRadiusInMeter: true);
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
                maxZoom: maxZoomSupported,
                onMapEvent: (event) => state.update() // @Speed Currently, we rebuild the MapView widget on every map event. Maybe this is slow.
                ),
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
                      // start alarm placement ui
                      if (!(state.isPlacingAlarm)) {
                        state.isPlacingAlarm = true;
                        state.update();
                        return;
                      }

                      // Save alarm
                      var alarmPlacementPosition = state.mapController.center;
                      var alarm = createAlarm(name: 'Alarm', position: alarmPlacementPosition, radius: state.alarmPlacementRadius);
                      addAlarm(alarm);
                      resetAlarmPlacementUIState();
                      state.update();
                    },
                    elevation: 4,
                    child: Icon(alarmPlacementIcon)),
                SizedBox(height: 10),
                (state.isPlacingAlarm)
                    ? FloatingActionButton(
                        onPressed: () {
                          resetAlarmPlacementUIState();
                          state.update();
                        },
                        elevation: 4,
                        child: Icon(Icons.cancel_rounded))
                    : SizedBox.shrink(),
              ],
            ),
          ),
          (state.isPlacingAlarm) // Display the slider only if we are placing an alarm.
              ? Positioned(
                  bottom: 150,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: Row(
                        children: [
                          Text('Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: state.alarmPlacementRadius,
                              onChanged: (value) {
                                state.alarmPlacementRadius = value;
                                state.update();
                              },
                              min: 100,
                              max: 3000,
                              divisions: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              : SizedBox.shrink(),
        ],
      );
    });
  }

  @override
  void dispose() {
    resetAlarmPlacementUIState();
    super.dispose();
  }
}

void placeNewAlarm() {
  ProxalarmState ps = Get.find<ProxalarmState>();

  // var center ps.mapController.center
}
