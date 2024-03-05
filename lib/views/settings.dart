import 'dart:io';

import 'package:feedback_sentry/feedback_sentry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:june/june.dart';
import 'package:loca_alert/constants.dart';
import 'package:loca_alert/loca_alert_state.dart';
import 'package:path_provider/path_provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      () => LocaAlertState(),
      builder: (state) {
        return SafeArea(
          child: Scrollbar(
            child: ListView(
              children: [
                /*Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SwitchListTile(
                    title: Text('Alarm Notification'),
                    value: state.notification,
                    onChanged: (value) {
                      changeAlarmNotification(newValue: value);
                    },
                    thumbIcon: thumbIcon,
                  ),
                ),*/
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Alarm Sound'),
                    trailing: Switch(
                      value: state.alarmSound,
                      thumbIcon: thumbIcon,
                      onChanged: (value) {
                        changeAlarmSound(newValue: value);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Vibration'),
                    trailing: Switch(
                      value: state.vibration,
                      thumbIcon: thumbIcon,
                      onChanged: (value) {
                        changeVibration(newValue: value);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Show Closest Off-Screen Alarm'),
                    trailing: Switch(
                      value: state.showClosestOffScreenAlarm,
                      onChanged: (value) {
                        changeShowClosestOffScreenAlarm(newValue: value);
                      },
                      thumbIcon: thumbIcon,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Location Settings'),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: Geolocator.openLocationSettings,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Give Feedback'),
                    trailing: Icon(Icons.feedback_rounded),
                    onTap: () {
                      BetterFeedback.of(context).showAndUploadToSentry();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Clear Map Cache'),
                    subtitle: Text('This can free up storage on your device.'),
                    trailing: Icon(Icons.delete_rounded),
                    onTap: () async {
                      var scaffoldMessenger = ScaffoldMessenger.of(context); // Don't use Scaffold.of(context) across async gaps (according to flutter).

                      // Get size of map tile cache.
                      var applicationCacheDirectory = await getApplicationCacheDirectory();
                      if (!applicationCacheDirectory.existsSync()) {
                        debugPrint('Warning: application cache directory does not exist');
                        return;
                      }

                      var mapTileCachePath = '${applicationCacheDirectory.path}${Platform.pathSeparator}$mapTileCacheFilename';
                      var mapTileCacheDirectory = Directory(mapTileCachePath);

                      var entities = mapTileCacheDirectory.listSync();
                      var totalDirectorySizeInBytes = 0;
                      for (var entity in entities) {
                        var stat = await entity.stat();
                        totalDirectorySizeInBytes += stat.size;
                        debugPrint(entity.path);
                        debugPrint(stat.toString());
                      }

                      var bytesInAMegabyte = 1048576;
                      var totalDirectorySizeInMegabytes = totalDirectorySizeInBytes / bytesInAMegabyte;

                      // Clear map tile cache.
                      if (state.mapTileCacheStore != null) await state.mapTileCacheStore!.clean();
                      
                      var megabytesFreed = totalDirectorySizeInMegabytes.toStringAsFixed(0);
                      if (totalDirectorySizeInMegabytes < 1) {
                        megabytesFreed = '<1';
                      }
                      var message = 'Map tile cache cleared. $megabytesFreed MB(s) freed.';
                      debugPrint(message);

                      // Show snackbar.
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Container(padding: EdgeInsets.all(8), child: Text(message)),
                          duration: const Duration(seconds: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );

                    },
                  ),
                ),
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Print Alarms In Storage.'),
                      trailing: Icon(Icons.alarm_rounded),
                      onTap: () async {
                        var directory = await getApplicationDocumentsDirectory();
                        var alarmsPath = '${directory.path}${Platform.pathSeparator}$alarmsFilename';
                        var alarmsFile = File(alarmsPath);

                        if (!alarmsFile.existsSync()) {
                          debugPrint('Warning: No alarms file found in storage.');
                          return;
                        }

                        var alarmJsons = await alarmsFile.readAsString();
                        if (alarmJsons.isEmpty) {
                          debugPrint('No alarms found in storage.');
                          return;
                        }

                        debugPrint('Alarms found in storage: $alarmJsons');
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// for switch icons.
final MaterialStateProperty<Icon?> thumbIcon = MaterialStateProperty.resolveWith<Icon?>((states) {
  if (states.contains(MaterialState.selected)) return const Icon(Icons.check_rounded);
  return const Icon(Icons.close_rounded);
});
