import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/proxalarm_state.dart';

List<String> pokemons = ['pikachu', 'charmander', 'squirtle', 'bullbasaur', 'snorlax', 'mankey', 'psyduck', 'meowth'];

// List<(String name, Icon b)> blahs = [];

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final listDropdownController = DropdownController();
  List<CoolDropdownItem<String>> pokemonDropdownItems = [];

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
            top: statusBarHeight + 25,
            right: 25,
            child: CoolDropdown(
              dropdownList: [
                CoolDropdownItem(
                    label: 'alarm',
                    value: 'alarm',
                    icon: IconButton(
                      icon: Icon(Icons.pin_drop_rounded, size: 25),
                      onPressed: () => print('drop an new alarm!'),
                    )),
                CoolDropdownItem(label: 'user', value: 'user', icon: SizedBox(height: 25, width: 25, child: Icon(Icons.my_location_rounded)))
              ],
              controller: DropdownController(duration: Duration(milliseconds: 300)),
              onChange: (value) {}, // Do nothing because we don't care about selection of dropdown items.
              dropdownOptions: DropdownOptions(color: Theme.of(context).colorScheme.surface),
              resultOptions: ResultOptions(
                width: 50,
                boxDecoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                openBoxDecoration:
                    BoxDecoration(color: paleBlue, borderRadius: BorderRadius.all(Radius.circular(10)), border: Border.all(color: Colors.black)),
                render: ResultRender.none,
                icon: SizedBox(width: 25, height: 25, child: Icon(Icons.keyboard_arrow_down_rounded)),
              ),
              dropdownItemOptions: DropdownItemOptions(
                  render: DropdownItemRender.icon,
                  selectedPadding: EdgeInsets.zero,
                  mainAxisAlignment: MainAxisAlignment.center,
                  selectedBoxDecoration: BoxDecoration(border: Border.all(width: 0))),
            ),
          ),
          Positioned(
            top: statusBarHeight + 25,
            left: 25,
            child: CoolDropdown(
              controller: listDropdownController,
              dropdownList: pokemonDropdownItems,
              onChange: (dropdownItem) {},
              resultOptions: ResultOptions(
                width: 50,
                render: ResultRender.none,
                icon: SizedBox(
                  width: 25,
                  height: 25,
                  child: SvgPicture.asset(
                    'assets/pokeball.svg',
                  ),
                ),
              ),
              dropdownItemOptions: DropdownItemOptions(
                render: DropdownItemRender.icon,
                selectedPadding: EdgeInsets.zero,
                mainAxisAlignment: MainAxisAlignment.center,
                selectedBoxDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.black.withOpacity(0.7),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  @override
  void initState() {
    for (var i = 0; i < pokemons.length; i++) {
      pokemonDropdownItems.add(
        CoolDropdownItem<String>(
            label: '${pokemons[i]}',
            icon: Container(
              height: 25,
              width: 25,
              child: SvgPicture.asset(
                'assets/${pokemons[i]}.svg',
              ),
            ),
            value: '${pokemons[i]}'),
      );
    }
    super.initState();
  }
}
