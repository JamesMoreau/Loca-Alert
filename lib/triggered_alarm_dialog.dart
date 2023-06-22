import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proxalarm/alarm.dart';
import 'package:proxalarm/proxalarm_state.dart';

import 'constants.dart';

void showAlarmDialog(BuildContext context, String alarmId) {
  var ps = Get.find<ProxalarmState>();
  var alarm = getAlarmById(alarmId);

  if (alarm == null) {
    debugPrint('Error: Unable to retrieve triggered alarm.');
    ps.alarmIsCurrentlyTriggered = false;
    return;
  }

  showGeneralDialog<void>(
    context: context,
    pageBuilder: (context, a1, a2) => Dialog.fullscreen(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: paleBlue,
        padding: EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            children: [
              Text(
                'Alarm Triggered',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
              ),
              // Text(alarm.name),
              // SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    var dismissedAlarm = createAlarm(
                      name: alarm.name,
                      position: alarm.position,
                      radius: alarm.radius,
                      color: alarm.color,
                      active: false, // deactivate the alarm
                    );
                    updateAlarmById(alarmId, dismissedAlarm);
                    Navigator.pop(context);
                    ps.alarmIsCurrentlyTriggered = false;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    minimumSize: Size(200, 50),
                  ),
                  child: Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // showGeneralDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  //     barrierColor: Colors.black45,
  //     transitionDuration: const Duration(milliseconds: 200),
  //     pageBuilder: (context, animation, secondaryAnimation) {
  //       return Center(
  //         child: Container(
  //           width: MediaQuery.of(context).size.width,
  //           height: MediaQuery.of(context).size.height,
  //           padding: EdgeInsets.all(20),
  //           color: Colors.white,
  //           child: 
  //         ),
  //       );
  //     });



