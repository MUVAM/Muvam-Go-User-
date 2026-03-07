import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';

class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String?) onLocationChanged;

  const LocationField({
    super.key,
    required this.controller,
    required this.onLocationChanged,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  String? _locationPoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.titleSmall14(context, text: 'Location', isTextWidget: true),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.kLocationFieldColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tap to get current location',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  readOnly: true,
                  onTap: _getCurrentLocation,
                ),
              ),
              GestureDetector(
                onTap: _getCurrentLocation,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Icons.my_location,
                    size: 20.sp,
                    color: AppColors.kMainColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => widget.controller.text = 'Getting location...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => widget.controller.clear());
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => widget.controller.clear());
          if (!mounted) return;
          CustomFlushbar.showError(
            context: context,
            message: 'Location permission denied',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => widget.controller.clear());
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location permission permanently denied.',
        );
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 20));
      } on TimeoutException {
        setState(() => widget.controller.clear());
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location request timed out. Please try again.',
        );
        return;
      }

      _locationPoint = 'POINT(${position.longitude} ${position.latitude})';
      widget.onLocationChanged(_locationPoint);

      String address = '';
      bool geocodingSuccessful = false;

      try {
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            final placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            ).timeout(const Duration(seconds: 10));

            if (placemarks.isNotEmpty) {
              final place = placemarks[0];
              final parts = <String>[
                if (place.street?.isNotEmpty == true) place.street!,
                if (place.subLocality?.isNotEmpty == true) place.subLocality!,
                if (place.locality?.isNotEmpty == true) place.locality!,
                if (place.administrativeArea?.isNotEmpty == true)
                  place.administrativeArea!,
                if (place.country?.isNotEmpty == true) place.country!,
              ];
              address = parts.join(', ');
              geocodingSuccessful = true;
              break;
            }
          } catch (e) {
            if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (_) {}

      if (geocodingSuccessful && address.isNotEmpty) {
        setState(() => widget.controller.text = address);
        if (!mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location captured successfully',
        );
      } else {
        setState(
          () => widget.controller.text =
              'Lat: ${position!.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
        );
        if (!mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location saved (GPS coordinates)',
        );
      }
    } catch (e) {
      setState(() {
        widget.controller.clear();
        _locationPoint = null;
      });
      widget.onLocationChanged(null);
      if (!mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to get location: ${e.toString()}',
      );
    }
  }
}
