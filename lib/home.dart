import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proximityalarm/alarms_view.dart';
import 'package:proximityalarm/map_view.dart';
import 'package:proximityalarm/proximity_alarm_state.dart';
import 'package:proximityalarm/settings_view.dart';

enum ProximityAlarmViews { alarms, map, settings }

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProximityAlarmState>(
      builder: (state) {
        return Scaffold(
          body: PageView(
            controller: state.pageController,
            physics: NeverScrollableScrollPhysics(), // Disable swipe gesture to change pages
            children: [
              AlarmsView(),
              MapView(),
              SettingsView(),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: NavigationBar(
              elevation: 3,
              onDestinationSelected: (int index) {
                state.currentView = ProximityAlarmViews.values[index];
                state.update();
                state.pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget getView(ProximityAlarmView v) {
  //   switch (v) {
  //     case ProximityAlarmViews.alarms:
  //       return AlarmsView();
  //     case ProximityAlarmViews.map:
  //       return MapView();
  //   }
  // }
}
