import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/features/auth/presentation/widgets/account_text_field.dart';
import 'package:muvam/features/home/presentation/screens/home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  String? _locationPoint;
  String? _city; // Store city separately

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  void _checkToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.checkTokenValidity();
    AppLogger.log('Token valid in create account: $token');

    // Also check stored token directly
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    AppLogger.log('Stored token in create account: $storedToken');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Text(
                  'Create Account',
                  style: ConstTextStyles.createAccountTitle,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please enter your correct details as it is on your government issued document.',
                  style: ConstTextStyles.createAccountSubtitle.copyWith(
                    color: Color(ConstColors.subtitleColor),
                  ),
                ),
                SizedBox(height: 30.h),
                AccountTextField(
                  label: 'First Name',
                  controller: firstNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Middle Name (Optional)',
                  controller: middleNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Last Name',
                  controller: lastNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Date of Birth',
                  controller: dobController,
                  backgroundColor: ConstColors.formFieldColor,
                  isDateField: true,
                  onDateSelected: () => _selectDate(context, dobController),
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Email Address',
                  controller: emailController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                _buildLocationField(),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Referral Code (Optional)',
                  controller: referralController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 40.h),
                _buildContinueButton(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: ConstTextStyles.fieldLabel),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(ConstColors.locationFieldColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: locationController,
                  style: ConstTextStyles.inputText,
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
                    color: Color(ConstColors.mainColor),
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
      // Show loading indicator
      setState(() {
        locationController.text = 'Getting location...';
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationController.clear();
          });
          if (!mounted) return;
          CustomFlushbar.showError(
            context: context,
            message: 'Location permission denied',
          );
          return;
        }
      }

      // Get position with longer timeout
      Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Location fetch timed out');
            },
          );

      // Store the coordinates immediately
      _locationPoint = 'POINT(${position.longitude} ${position.latitude})';
      AppLogger.log('Location Point: $_locationPoint');

      // Try to get address with much longer timeout and retry logic
      String address = '';
      bool geocodingSuccessful = false;

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          AppLogger.log('Geocoding attempt ${attempt + 1}...');

          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(Duration(seconds: 15));

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];

            // Extract city for API
            _city =
                place.locality ??
                place.subAdministrativeArea ??
                place.administrativeArea ??
                'Unknown';
            AppLogger.log('Extracted city: $_city');

            // Build a readable address
            List<String> addressParts = [];

            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }

            address = addressParts.join(', ');

            if (address.isEmpty) {
              address = _city ?? 'Your Location';
            }

            geocodingSuccessful = true;
            AppLogger.log('Geocoded address: $address');
            break;
          }
        } on TimeoutException catch (e) {
          AppLogger.log('Geocoding attempt ${attempt + 1} timed out: $e');
          if (attempt == 0) {
            await Future.delayed(Duration(milliseconds: 500));
          }
        } catch (e) {
          AppLogger.log('Geocoding attempt ${attempt + 1} failed: $e');
          break;
        }
      }

      // Update UI with result
      if (geocodingSuccessful && address.isNotEmpty) {
        setState(() {
          locationController.text = address;
        });

        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location captured successfully',
        );
      } else {
        // Use coordinates as fallback
        setState(() {
          locationController.text =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
          _city = 'Unknown'; // Set default city
        });

        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location saved (showing coordinates)',
        );
      }
    } catch (e) {
      AppLogger.log('Error getting location: $e');
      setState(() {
        locationController.clear();
      });

      if (!mounted) return;

      CustomFlushbar.showError(
        context: context,
        message: 'Failed to get location. Please try again.',
      );
    }
  }

  Widget _buildContinueButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GestureDetector(
          onTap: !authProvider.isLoading
              ? () async {
                  // Validate required fields
                  if (firstNameController.text.isEmpty) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Please enter your first name',
                    );
                    return;
                  }

                  if (lastNameController.text.isEmpty) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Please enter your last name',
                    );
                    return;
                  }

                  if (dobController.text.isEmpty) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Please select your date of birth',
                    );
                    return;
                  }

                  if (emailController.text.isEmpty) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Please enter your email',
                    );
                    return;
                  }

                  if (_locationPoint == null || _city == null) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Please select your location',
                    );
                    return;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  final phone =
                      prefs.getString('user_phone') ?? '+2341234567890';

                  // Create the request object
                  final request = RegisterUserRequest(
                    email: emailController.text.trim(),
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phone,
                    role: 'passenger',
                    location: _locationPoint,
                  );

                  // Convert to JSON and add missing fields
                  final requestJson = request.toJson();

                  // Add the missing fields that API expects
                  requestJson['middle_name'] =
                      middleNameController.text.trim().isEmpty
                      ? ''
                      : middleNameController.text.trim();
                  requestJson['date_of_birth'] = dobController.text.trim();
                  requestJson['city'] = _city!;
                  requestJson['service_type'] = 'taxi';

                  AppLogger.log('Registration request: $requestJson');

                  // Send the modified JSON directly to the provider
                  final success = await authProvider.registerUserWithJson(
                    requestJson,
                  );

                  if (success) {
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    CustomFlushbar.showError(
                      context: context,
                      message:
                          authProvider.errorMessage ??
                          'Failed to register user',
                    );
                  }
                }
              : null,
          child: Container(
            width: 353.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: !authProvider.isLoading
                  ? Color(ConstColors.mainColor)
                  : Color(ConstColors.fieldColor),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: authProvider.isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // Default to year 2000
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Format as MM/DD/YYYY to match API expectation
      String month = picked.month.toString().padLeft(2, '0');
      String day = picked.day.toString().padLeft(2, '0');
      controller.text = "$month/$day/${picked.year}";
      AppLogger.log('Date selected: ${controller.text}');
    }
  }
}
