import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarms_view.dart';
import 'package:proxalarm/map_view.dart';
import 'package:proxalarm/proxalarm_state.dart';
import 'package:proxalarm/settings_view.dart';

enum ProxalarmViews { alarms, map, settings }

class Home extends StatelessWidget {
  ProxalarmState ps = Get.find<ProxalarmState>();
  Home({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProxalarmState>(builder: (state) {
      return Scaffold(
        body: PageView(
            controller: ps.pageController,
            physics: NeverScrollableScrollPhysics(), // Disable swipe gesture to change pages
            children: [
              AlarmsView(),
              MapView(),
              SettingsView(),
            ]),
        extendBody: true,
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          child: NavigationBar(
              elevation: 3,
              onDestinationSelected: (int index) {
                state.currentView = ProxalarmViews.values[index];
                state.update();
                ps.pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
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
