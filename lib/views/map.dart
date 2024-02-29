import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:geolocator/geolocator.dart';
import 'package:june/june.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/constants.dart';
import 'package:location_alarm/location_alarm_state.dart';
import 'package:location_alarm/main.dart';
import 'package:location_alarm/models/alarm.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

	@override
	Widget build(BuildContext context) {
		return JuneBuilder(
      () => LocationAlarmState(),
			builder: (state) {
				var statusBarHeight = MediaQuery.of(context).padding.top;
        var screenSize = MediaQuery.of(context).size;

				// Display user's location on the map.
				var userLocationMarker = <Marker>[];
				if (state.userLocation != null)
					userLocationMarker.addAll([
						Marker(
							point: state.userLocation!,
							child: Icon(Icons.circle, color: Colors.blue),
						),
						Marker(
							point: state.userLocation!,
							child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
						),
					]);

				// If no alarms are currently visible on screen, show an arrow pointing towards the closest alarm (if there is one).
				var showClosestAlarmIndicator = state.closestAlarm != null && !state.closestAlarmIsInView && state.showClosestOffScreenAlarm;
				var arrow = SizedBox.shrink() as Widget;
				var indicatorAlarmIcon = <Widget>[];

				var angle = 0.0;
				var arrowRotation = 0.0;
				var ellipseWidth = screenSize.width * 0.8;
				var ellipseHeight = screenSize.height * 0.65;

				if (showClosestAlarmIndicator) {
					var indicatorColor = state.closestAlarm!.color;
					arrow = Transform.rotate(angle: -pi / 2 ,child: Icon(Icons.arrow_forward_ios, color: indicatorColor, size: 26));
					indicatorAlarmIcon.addAll([ Icon(Icons.circle, color: Colors.grey.shade800, size: 36), Icon(Icons.circle, color: paleBlue, size: 34), Icon(Icons.pin_drop_rounded, color: indicatorColor, size: 26)]);

					// Calculate the angle between the center of the map and the closest alarm
					var centerOfMap = state.mapController.camera.center;
					arrowRotation = angle = getAngleBetweenTwoPositions(centerOfMap, state.closestAlarm!.position);
					angle = (arrowRotation + 3 * pi / 2) % (2 * pi); // Compensate the for y-axis pointing downwards on Transform.translate().
				}

				// Display the alarms as circles on the map.
				var alarmCircles = <CircleMarker>[];
				var alarmMarkers = <Marker>[];
				if (state.showMarkersInsteadOfCircles) {
					// These are the same alarms as the circles, but they are markers instead. They are only visible when the user is zoomed out beyond circleToMarkerZoomThreshold.
					for (var alarm in state.alarms) {
						var marker = Marker(
							point: alarm.position,
							child: Icon(Icons.pin_drop_rounded, color: alarm.color, size: 30),
						);

						alarmMarkers.add(marker);
					}
				} else {
					for (var alarm in state.alarms) {
						var circle = CircleMarker(
							point: alarm.position,
							color: alarm.color.withOpacity(alarmColorOpacity),
							borderColor: alarmBorderColor,
							borderStrokeWidth: alarmBorderWidth,
							radius: alarm.radius,
							useRadiusInMeter: true,
						);

						alarmCircles.add(circle);
					}
				}

				// Overlay the alarm placement ui on top of the map. This is only visible when the user is placing an alarm.
				CircleMarker? alarmPlacementCircle;
				if (state.isPlacingAlarm) {
					var centerOfMap = state.mapController.camera.center;
					var alarmPlacementPosition = centerOfMap;
					alarmPlacementCircle = CircleMarker(
						point: alarmPlacementPosition,
						radius: state.alarmPlacementRadius,
						color: Colors.redAccent.withOpacity(0.5),
						borderColor: Colors.black,
						borderStrokeWidth: 2,
						useRadiusInMeter: true,
					);
				}

				// If the map is locked to the user's location, disable move interaction.
				var myInteractiveFlags = InteractiveFlag.all & ~InteractiveFlag.rotate;
				if (state.followUserLocation) myInteractiveFlags = myInteractiveFlags & ~InteractiveFlag.pinchMove & ~InteractiveFlag.drag & ~InteractiveFlag.flingAnimation;

				return Stack(
					alignment: Alignment.center,
					children: [
						FlutterMap(
							mapController: state.mapController,
							options: MapOptions(
								initialCenter: LatLng(0, 0),
								initialZoom: initialZoom,
								interactionOptions: InteractionOptions(flags: myInteractiveFlags),
								keepAlive: true, // Keep the map alive when it is not visible.
								onMapEvent: myOnMapEvent,
								onMapReady: myOnMapReady,
							),
							children: [
                TileLayer(
                  urlTemplate: openStreetMapTemplateUrl,
                  userAgentPackageName: 'com.location_alarm.app',
                  tileProvider: CachedTileProvider(
                    maxStale: const Duration(days: 30),
                    store: state.mapTileCacheStore!,
                  ),
                ),
                if (state.showMarkersInsteadOfCircles) MarkerLayer(markers: alarmMarkers) else CircleLayer(circles: alarmCircles),
                if (alarmPlacementCircle != null) CircleLayer(circles: [alarmPlacementCircle]),
								if (state.userLocation != null) MarkerLayer(markers: userLocationMarker),
							],
						),
						if (showClosestAlarmIndicator) ...[
							// Display the arrow pointing towards the closest alarm.
							IgnorePointer(
								child: Center(
									child: Transform.translate(
										offset: Offset((ellipseWidth / 2) * cos(angle), (ellipseHeight / 2) * sin(angle)), // Move the arrow to the edge of the ellipse.
										child: Transform.rotate(
											angle: arrowRotation,
											child: arrow,
										),
									),
								),
							),
							IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: Offset((ellipseWidth / 2 - 26) * cos(angle), (ellipseHeight / 2 - 26) * sin(angle)),
                    child: Stack(
											alignment: Alignment.center,
											children: indicatorAlarmIcon,
										),
                  ),
                ),
              ),
            ],
						Positioned(
							// Attribution to OpenStreetMap
							top: statusBarHeight + 5,
							child: Align(
								child: Container(
									padding: EdgeInsets.all(3),
									decoration: BoxDecoration(
										color: Colors.white.withOpacity(0.7),
										borderRadius: BorderRadius.circular(8),
									),
									child: Text(
										'© OpenStreetMap contributors',
									),
								),
							),
						),
						Positioned(
							// Place the alarm placement buttons in the top right corner.
							top: statusBarHeight + 10,
							right: 15,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.end,
								mainAxisAlignment: MainAxisAlignment.spaceAround,
								children: [
									if (state.followUserLocation) ...[
                    FloatingActionButton(
                      onPressed: followOrUnfollowUserLocation,
                      elevation: 4,
                      backgroundColor: Color.fromARGB(255, 216, 255, 218),
                      child: Icon(CupertinoIcons.location_fill),
                    ),
                  ] else ...[ 
                    FloatingActionButton(
                      onPressed: followOrUnfollowUserLocation,
                      elevation: 4,
                      child: Icon(Icons.lock_rounded),
                    ),
                  ],
									SizedBox(height: 10),
									if (state.isPlacingAlarm) ...[
										// Show the confirm and cancel buttons when the user is placing an alarm.
										FloatingActionButton(
											onPressed: () {
												// Save alarm
												var centerOfMap = state.mapController.camera.center;
												var alarmPlacementPosition = centerOfMap;
												var alarm = createAlarm(name: 'Alarm', position: alarmPlacementPosition, radius: state.alarmPlacementRadius);
												addAlarm(alarm);
												resetAlarmPlacementUIState();
												state.setState();
											},
											elevation: 4,
											child: Icon(Icons.check),
										),
										SizedBox(height: 10),
										FloatingActionButton(
											onPressed: () {
												resetAlarmPlacementUIState();
												state.setState();
											},
											elevation: 4,
											child: Icon(Icons.cancel_rounded),
										),
									] else ...[
										// Show the place alarm button when the user is not placing an alarm.
										FloatingActionButton(
											onPressed: () {
												state.isPlacingAlarm = true;
												state.followUserLocation = false;
												state.setState();
											},
											elevation: 4,
											child: Icon(Icons.pin_drop_rounded),
										),
									],
									SizedBox.shrink(),
								],
							),
						),
						if (state.isPlacingAlarm) // Show the slider to adjust the new alarm's radius.
							Positioned(
								bottom: 150,
								child: Container(
									width: MediaQuery.of(context).size.width * 0.9,
									decoration: BoxDecoration(
										color: Theme.of(context).colorScheme.primaryContainer,
										borderRadius: BorderRadius.all(Radius.circular(15)),
										boxShadow: [
											BoxShadow(
												color: Colors.grey.withOpacity(0.5),
												spreadRadius: 2,
												blurRadius: 5,
												offset: Offset(0, 3),
											),
										],
									),
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
										child: Row(
											children: [
												Text('Size:', style: TextStyle(fontWeight: FontWeight.bold)),
												Expanded(
													child: Slider(
														value: state.alarmPlacementRadius,
														onChanged: (value) {
															state.alarmPlacementRadius = value;
															state.setState();
														},
														min: 100,
														max: 3000,
														divisions: 100,
													),
												),
											],
										),
									),
								),
							)
						else
							SizedBox.shrink(),
					],
				);
			},
		);
	}

	void myOnMapEvent(MapEvent event) {
		var state = June.getState(LocationAlarmState());

		var centerOfMap = state.mapController.camera.center;

		// Update the closest alarm stuff.
		var alarms = state.alarms;
		state.closestAlarm = getClosestAlarmToPosition(centerOfMap, alarms);

		// Update whether the closest alarm is in view.
		if (state.closestAlarm != null) {
			var cameraBounds = state.mapController.camera.visibleBounds;
			if (cameraBounds.contains(state.closestAlarm!.position))
				state.closestAlarmIsInView = true;
			else
				state.closestAlarmIsInView = false;
		}

		// If the user is zoomed out, show the alarms as markers instead of circles.
		if (state.mapController.camera.zoom < circleToMarkerZoomThreshold)
			state.showMarkersInsteadOfCircles = true;
		else
			state.showMarkersInsteadOfCircles = false;

		state.setState();
	}

	Future<void> myOnMapReady() async {
		// Check location permission and request it if necessary.
		var permission = await Geolocator.checkPermission();
		if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
			await checkPermissionAndMaybeInitializeUserPositionStream();
			await moveMapToUserLocation();
			return; // the user has already granted location permissions.
		}

		if (permission == LocationPermission.denied) {
			// The user has denied location permissions. We can ask for them again.
			var permission = await Geolocator.requestPermission();
			if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
				await checkPermissionAndMaybeInitializeUserPositionStream();
				await moveMapToUserLocation();
			}
			return;
		}

		if (permission == LocationPermission.deniedForever) {
			debugPrint('Warning: User has denied location permissions forever.');
			ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!).showSnackBar(
				SnackBar(
					behavior: SnackBarBehavior.floating,
					content: Container(
						padding: const EdgeInsets.all(8),
						child: Text('Location permissions are required to use this app.'),
					),
					action: SnackBarAction(label: 'Settings', onPressed: Geolocator.openAppSettings),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
				),
			);
		}
	}

  void followOrUnfollowUserLocation() {
    var state = June.getState(LocationAlarmState());
    if (state.followUserLocation) {
      state.followUserLocation = false;
			state.setState();
			return;
		}

		// Check if we actually can follow the user's location. If not, show a snackbar.
		if (state.userLocation == null) {
			debugPrint("Error: Unable to follow the user's location.");
			ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!).showSnackBar(
				SnackBar(
					behavior: SnackBarBehavior.floating,
					content: Container(
						padding: const EdgeInsets.all(8),
						child: Text('Unable to follow your location. Are location services permitted?'),
					),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
				),
			);
			return;
		}

		state.followUserLocation = true;
		moveMapToUserLocation();
		state.setState();
  }
}

Future<void> moveMapToUserLocation() async {
	var state = June.getState(LocationAlarmState());

	var userPosition = state.userLocation;
	if (userPosition == null) {
		debugPrint('Error: Unable to move map to user location.');
		return;
	}

	var currentZoom = state.mapController.camera.zoom;
	state.mapController.move(userPosition, currentZoom);

	debugPrint('Moving map to user location.');
}

double getAngleBetweenTwoPositions(LatLng from, LatLng to) => atan2(to.longitude - from.longitude, to.latitude - from.latitude);

Future<void> navigateToAlarm(Alarm alarm) async {
	var state = June.getState(LocationAlarmState());
	
	if (state.currentView != ProximityAlarmViews.map) {
		state.currentView = ProximityAlarmViews.map;
		
		// @Hack: This is bad programming, but it works for now. We need to wait for the map widget to load before we can move the map.
		await state.pageController.animateToPage(state.currentView.index,	duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
	}
	
	state.followUserLocation = false; // Stop following the user's location before moving the map.
	state.setState();

	state.mapController.move(alarm.position, initialZoom);
}
