// Additional methods for HomeScreen to support pre-booking and payment method handling

import 'package:flutter/material.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:muvam/core/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Add these methods to your HomeScreen class

Future<RideResponse?> _requestRide({bool isScheduled = false}) async {
  if (_currentEstimate == null || selectedVehicle == null) {
    throw Exception('No estimate or vehicle selected');
  }

  final selectedPriceData = _currentEstimate!.priceList[selectedVehicle!];
  final vehicleType = selectedPriceData['vehicle_type'];

  String? scheduledDateTime;
  if (isScheduled) {
    final scheduledDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    scheduledDateTime = scheduledDate.toIso8601String();
  }

  final request = RideRequest(
    pickup: _pickupCoordinates != null
        ? '${_pickupCoordinates!.latitude},${_pickupCoordinates!.longitude}'
        : '${_currentLocation.latitude},${_currentLocation.longitude}',
    dest: _destinationCoordinates != null
        ? '${_destinationCoordinates!.latitude},${_destinationCoordinates!.longitude}'
        : '${_currentLocation.latitude + 0.01},${_currentLocation.longitude + 0.01}',
    pickupAddress: fromController.text.isNotEmpty
        ? fromController.text
        : 'Current location',
    destAddress: toController.text,
    stopAddress: stopController.text.isNotEmpty ? stopController.text : null,
    serviceType: 'taxi',
    vehicleType: vehicleType,
    paymentMethod: selectedPaymentMethod,
    scheduled: isScheduled,
    scheduledAt: scheduledDateTime,
  );

  return await _rideService.requestRide(request);
}

Future<void> _estimateRide() async {
  if (_pickupCoordinates == null || _destinationCoordinates == null) {
    return;
  }

  final request = RideEstimateRequest(
    pickup: '${_pickupCoordinates!.latitude},${_pickupCoordinates!.longitude}',
    dest: '${_destinationCoordinates!.latitude},${_destinationCoordinates!.longitude}',
    destAddress: toController.text,
    serviceType: 'taxi',
    vehicleType: 'regular', // Default for estimation
  );

  try {
    _currentEstimate = await _rideService.estimateRide(request);
    setState(() {});
  } catch (e) {
    print('Error estimating ride: $e');
    throw e;
  }
}

void _addActiveRideMarkers(Map<String, dynamic> ride) async {
  // Parse PostGIS POINT format: "POINT(longitude latitude)"
  final pickupLocation = ride['PickupLocation']?.toString();
  final destLocation = ride['DestLocation']?.toString();
  final stopLocation = ride['StopLocation']?.toString();

  LatLng? pickupCoords;
  LatLng? destCoords;
  LatLng? stopCoords;

  if (pickupLocation != null && pickupLocation.contains('POINT')) {
    final coords = _parsePostGISPoint(pickupLocation);
    if (coords != null) pickupCoords = coords;
  }

  if (destLocation != null && destLocation.contains('POINT')) {
    final coords = _parsePostGISPoint(destLocation);
    if (coords != null) destCoords = coords;
  }

  if (stopLocation != null && stopLocation.contains('POINT')) {
    final coords = _parsePostGISPoint(stopLocation);
    if (coords != null) stopCoords = coords;
  }

  // Create markers
  final markers = <Marker>{};

  if (pickupCoords != null) {
    final pickupIcon = await _createBitmapDescriptorFromWidget(
      _buildPickupMarkerWidget(),
      size: Size(247.w, 50.h),
    );
    markers.add(Marker(
      markerId: MarkerId('active_pickup'),
      position: pickupCoords,
      icon: pickupIcon,
      anchor: Offset(0.5, 1.0),
    ));
  }

  if (destCoords != null) {
    final dropoffIcon = await _createBitmapDescriptorFromWidget(
      _buildDropoffMarkerWidget(),
      size: Size(242.w, 48.h),
    );
    markers.add(Marker(
      markerId: MarkerId('active_dropoff'),
      position: destCoords,
      icon: dropoffIcon,
      anchor: Offset(0.5, 1.0),
    ));
  }

  if (stopCoords != null) {
    final stopIcon = await _createBitmapDescriptorFromWidget(
      _buildStopMarkerWidget(),
      size: Size(200.w, 40.h),
    );
    markers.add(Marker(
      markerId: MarkerId('active_stop'),
      position: stopCoords,
      icon: stopIcon,
      anchor: Offset(0.5, 1.0),
    ));
  }

  setState(() {
    _mapMarkers = markers;
  });

  // Fit camera to show all markers
  if (markers.isNotEmpty && _mapController != null) {
    final positions = markers.map((m) => m.position).toList();
    final bounds = _calculateBounds(positions);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }
}

LatLng? _parsePostGISPoint(String pointString) {
  try {
    // Remove "POINT(" and ")" and split by space
    final coords = pointString
        .replaceAll('POINT(', '')
        .replaceAll(')', '')
        .split(' ');
    
    if (coords.length == 2) {
      final longitude = double.parse(coords[0]);
      final latitude = double.parse(coords[1]);
      return LatLng(latitude, longitude);
    }
  } catch (e) {
    print('Error parsing PostGIS point: $e');
  }
  return null;
}

LatLngBounds _calculateBounds(List<LatLng> positions) {
  double minLat = positions.first.latitude;
  double maxLat = positions.first.latitude;
  double minLng = positions.first.longitude;
  double maxLng = positions.first.longitude;

  for (final pos in positions) {
    minLat = math.min(minLat, pos.latitude);
    maxLat = math.max(maxLat, pos.latitude);
    minLng = math.min(minLng, pos.longitude);
    maxLng = math.max(maxLng, pos.longitude);
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

void _showRatingSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setRatingState) {
        int selectedRating = 0;
        final TextEditingController commentController = TextEditingController();

        return Container(
          height: 400.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Text(
                'Rate your driver',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setRatingState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40.sp,
                      color: index < selectedRating ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (_lastCompletedRideId != null) {
                          _dismissedRatingRides.add(_lastCompletedRideId!);
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Skip'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedRating > 0
                          ? () async {
                              if (_lastCompletedRideId != null) {
                                try {
                                  await _rideService.rateRide(
                                    rideId: _lastCompletedRideId!,
                                    score: selectedRating,
                                    comment: commentController.text,
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  print('Error rating ride: $e');
                                }
                              }
                            }
                          : null,
                      child: Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildDrawerItem(String title, String iconPath, {VoidCallback? onTap}) {
  return ListTile(
    leading: Image.asset(iconPath, width: 24.w, height: 24.h),
    title: Text(title),
    onTap: onTap,
  );
}