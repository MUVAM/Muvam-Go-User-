import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(6.5244, 3.3792);
  String _selectedAddress = '';
  bool _isLoadingLocation = true;
  bool _isLoadingAddress = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = location;
        _isLoadingLocation = false;
      });
      _updateMarker(location);
      _getAddressFromLatLng(location);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() => _selectedLocation = newPosition);
            _getAddressFromLatLng(newPosition);
          },
        ),
      };
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'address': _selectedAddress,
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            onTap: (position) {
              setState(() => _selectedLocation = position);
              _updateMarker(position);
              _getAddressFromLatLng(position);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (_isLoadingLocation)
            Container(
              color: AppColors.kWhiteColor.withOpacity(0.8),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.kMainColor),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(16.w),
                color: AppColors.kWhiteColor,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'Select Location',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.kWhiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuvamTexts.bodyLarge16(
                      context,
                      text: 'Selected Location',
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 10.h),
                    if (_isLoadingAddress)
                      Row(
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.kMainColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          MuvamTexts.bodyMedium14(
                            context,
                            text: 'Getting address...',
                            isTextWidget: true,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.kMainColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: MuvamTexts.bodyMedium14(
                              context,
                              text: _selectedAddress.isEmpty
                                  ? 'Tap on map to select location'
                                  : _selectedAddress,
                              isTextWidget: true,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 47.h,
                      child: ElevatedButton(
                        onPressed: _selectedAddress.isEmpty
                            ? null
                            : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kMainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: MuvamTexts.button16(
                          context,
                          text: 'Confirm Location',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
