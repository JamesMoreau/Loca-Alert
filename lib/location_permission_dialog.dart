import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_alarm/constants.dart';

void showLocationPermissionDialog(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    pageBuilder: (context, a1, a2) {
      return Dialog.fullscreen(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: paleBlue,
          padding: EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.location_on,
                      size: 120,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Location Permission Required',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'This app requires access to your location to function properly. Please grant location access to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<bool> ok() async {
    var permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return true;
    }

    return false;
  }
}
