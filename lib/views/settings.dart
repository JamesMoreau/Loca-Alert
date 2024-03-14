import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:loca_alert/constants.dart';
import 'package:loca_alert/loca_alert_state.dart';
import 'package:loca_alert/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      () => LocaAlertState(),
      builder: (state) {
        var versionString = version ?? 'Unknown';
        var appNameString = appName ?? 'Unknown';

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
                    title: Text(appNameString),
                    subtitle: Text('Version: $versionString'),
                    trailing: Icon(Icons.info_rounded),
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
                    onTap: () => AppSettings.openAppSettings(type: AppSettingsType.location),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Give Feedback'),
                    trailing: Icon(Icons.feedback_rounded),
                    onTap: () async {
                      var url = 'https://apps.apple.com/app/id$appleID';
                      var uri = Uri.parse(url);
                      var canLaunch = await canLaunchUrl(uri);
                      if (!canLaunch) {
                        if (kDebugMode) print('Cannot launch url.');
                        return;
                      }

                      debugPrint('Opening app store page for feedback.');
                      await launchUrl(uri);
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

                      // Clear map tile cache.
                      if (state.mapTileCacheStore != null) await state.mapTileCacheStore!.clean();
                      
                      debugPrint('Map tile cache cleared.');

                      // Show snackbar.
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Container(padding: EdgeInsets.all(8), child: Text('Map tile cache cleared.')),
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
                      title: Text('DEBUG: Print Alarms In Storage.'),
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
