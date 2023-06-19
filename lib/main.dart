import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarms_view.dart';
import 'package:proxalarm/constants.dart';
import 'package:proxalarm/map_view.dart';
import 'package:proxalarm/proxalarm_state.dart';

/* 
  TODO:
    short term:
    place alarm manually (ui plus icon at the top)
    show user's current location on map.
    always navigate to user's location on map load.
    calculate if user is inside an alarm.
    settings: alarm sound, vibration?, location settings

    long term:
    switch map tile provider (mapbox, thunderforest, etc)
    checkout mapbox: https://docs.fleaflet.dev/tile-servers/using-mapbox
    go alarm on map. using MapController
    tile chaching
    go to user location on map if offscreen.
    show some sort icon on map for alarm if too zoomed out to see the circle. (could use current zoom level to determine this).
    Logo
    show something when user is too zoomed in. Use current zoom level to determine this.
    get distance to closest alarm. have some sort of ui layer that points towards the alarm from current location if it is offscreen.
*/

enum Views { map, alarms }

void main() {
  final ProxalarmState ps = Get.put(ProxalarmState()); // Inject the global app state into memory.
  loadAlarmsFromSharedPreferences();
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
  final pageController = PageController(initialPage: Get.find<ProxalarmState>().currentView.index);

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(builder: (state) {
      return Scaffold(
        body: PageView(
            controller: pageController,
            physics: NeverScrollableScrollPhysics(), // Disable swipe gesture to change pages
            children: [
              AlarmsView(),
              MapView(),
            ]),
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
                pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
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
    });
  }

  // Widget getView(ProxalarmView v) {
  //   switch (v) {
  //     case ProxalarmView.alarms:
  //       return AlarmsView();
  //     case ProxalarmView.map:
  //       return MapView();
  //   }
  // }
}
