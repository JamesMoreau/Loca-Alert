import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/main.dart';

class ProxalarmState extends GetxController {
  Rx<View> currentView = View.alarms.obs;
  RxList<Alarm> alarms = <Alarm>[Alarm(name: "First alarm", position: const LatLng(0, 0), radius: 10.0)].obs;
}
