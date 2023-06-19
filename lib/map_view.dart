import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
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
          FlutterMap( // Map
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
          Positioned( // Dropdown Menu
            top: statusBarHeight + 25.0,
            right: 25.0,
            child: CoolDropdown(
              dropdownList: [CoolDropdownItem(label: '', value: '', icon: SizedBox(height: 25, width: 25, child: Icon(Icons.alarm)))],
              controller: DropdownController(duration: Duration(milliseconds: 300)),
              onChange: (value) {},
              dropdownOptions: DropdownOptions(color: Theme.of(context).colorScheme.surface),
              resultOptions: ResultOptions(
                width: 50,
                boxDecoration: BoxDecoration(
                  color: Color(0xffeaf0f5),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1a9E9E9E),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                openBoxDecoration: BoxDecoration(
                    color: Color(0xffeaf0f5),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border(
                      top: BorderSide(width: 1, color: Colors.black),
                      bottom: BorderSide(width: 1, color: Colors.black),
                      left: BorderSide(width: 1, color: Colors.black),
                      right: BorderSide(width: 1, color: Colors.black),
                    )),
                render: ResultRender.none,
                icon: SizedBox(width: 25, height: 25, child: Icon(Icons.keyboard_arrow_down_rounded)),
              ),
            ),
          ),
        ],
      );
    });
  }
}
