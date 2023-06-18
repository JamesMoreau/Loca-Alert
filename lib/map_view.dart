import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/proxalarm_state.dart';

class MapView extends StatelessWidget {
  const MapView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
      final statusBarHeight = MediaQuery.of(context).padding.top;

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
            mapController: state.mapController,
            options: MapOptions(center: LatLng(51.509364, -0.128928), zoom: 9.2, interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate, maxZoom: maxZoomSupported),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              CircleLayer(circles: circles),
            ],
          ),
          Positioned(
            top: statusBarHeight + 16.0,
            right: 16.0,
            child: FloatingActionButton(
              // backgroundColor: Theme.of(context).,
              onPressed: () {
                // Handle the tap on the floating button here
                // For example, open a dialog or navigate to a new screen
              },
              child: Icon(Icons.add),
            ),
          ),
        ],
      );
    });
  }
}