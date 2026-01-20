import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/features/auth/presentation/widgets/account_text_field.dart';
import 'package:muvam/features/auth/presentation/screens/state_selection_screen.dart';

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
  final TextEditingController stateController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? _selectedState;
  String? _locationPoint;

  @override
  void initState() {
    super.initState();
    _checkToken();

    firstNameController.addListener(_updateButtonState);
    lastNameController.addListener(_updateButtonState);
    dobController.addListener(_updateButtonState);
    emailController.addListener(_updateButtonState);
    stateController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    return firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        dobController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        _selectedState != null;
  }

  void _checkToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.checkTokenValidity();
    AppLogger.log('Token valid in create account: $token');

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    AppLogger.log('Stored token in create account: $storedToken');
  }

  @override
  void dispose() {
    firstNameController.removeListener(_updateButtonState);
    lastNameController.removeListener(_updateButtonState);
    dobController.removeListener(_updateButtonState);
    emailController.removeListener(_updateButtonState);
    stateController.removeListener(_updateButtonState);

    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    emailController.dispose();
    stateController.dispose();
    referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 25.h),
                  Center(
                    child: Text(
                      'Create Account',
                      style: ConstTextStyles.createAccountTitle,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Center(
                    child: Text(
                      'Please enter your correct details as it is \non your government issued document.',
                      style: ConstTextStyles.fieldLabel.copyWith(
                        color: Color(ConstColors.subtitleColor),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 35.h),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccountTextField(
                        label: 'First name',
                        controller: firstNameController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your first name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Middle name (Optional)',
                        controller: middleNameController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your middle name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Last name',
                        controller: lastNameController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your last name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Date of birth',
                        controller: dobController,
                        backgroundColor: ConstColors.formFieldColor,
                        isDateField: true,
                        hintText: 'MM/DD/YYYY',
                        onDateSelected: () =>
                            _selectDate(context, dobController),
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Email address',
                        controller: emailController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter your email address',
                      ),
                      SizedBox(height: 20.h),
                      _buildStateField(),
                      SizedBox(height: 20.h),
                      _buildLocationField(),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Referral code (Optional)',
                        controller: referralController,
                        backgroundColor: ConstColors.formFieldColor,
                        hintText: 'Enter referral code if you have one',
                      ),
                      SizedBox(height: 40.h),
                      _buildContinueButton(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildStateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select State', style: ConstTextStyles.fieldLabel),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StateSelectionScreen(),
              ),
            );

            if (result != null) {
              setState(() {
                _selectedState = result;
                stateController.text = result;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: Color(ConstColors.locationFieldColor),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stateController.text.isEmpty
                        ? 'Select State'
                        : stateController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: stateController.text.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 5.w,
                    height: 5.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        locationController.text = 'Getting location...';
      });

      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationController.clear();
        });
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      // Check permission status
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

      // Check if permission was permanently denied
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationController.clear();
        });
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message:
              'Location permission permanently denied. Please enable in settings.',
        );
        return;
      }

      // Get position with better error handling
      Position? position;
      try {
        position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(
              Duration(seconds: 20), // Increased timeout
              onTimeout: () {
                throw TimeoutException(
                  'Location fetch timed out after 20 seconds',
                );
              },
            );
      } on TimeoutException catch (e) {
        AppLogger.log('Position timeout: $e');
        setState(() {
          locationController.clear();
        });
        if (!mounted) return;
        CustomFlushbar.showError(
          context: context,
          message: 'Location request timed out. Please try again.',
        );
        return;
      }

      // Store location point immediately (this is most important)
      _locationPoint = 'POINT(${position.longitude} ${position.latitude})';
      AppLogger.log('Location Point (correct format): $_locationPoint');

      // Set default state using coordinates as fallback
      String fallbackCity =
          'City_${position.latitude.toStringAsFixed(2)}_${position.longitude.toStringAsFixed(2)}';
      _selectedState = fallbackCity;

      String address = '';
      bool geocodingSuccessful = false;

      // Try geocoding but don't fail if it doesn't work
      try {
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            AppLogger.log('Geocoding attempt ${attempt + 1}...');

            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            ).timeout(Duration(seconds: 10));

            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];

              // Extract city with multiple fallbacks
              String? city =
                  place.locality ??
                  place.subAdministrativeArea ??
                  place.administrativeArea ??
                  place.subLocality;

              if (city != null && city.isNotEmpty) {
                _selectedState = city;
                AppLogger.log('Extracted city: $_selectedState');
              }

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
              if (place.country != null && place.country!.isNotEmpty) {
                addressParts.add(place.country!);
              }

              address = addressParts.join(', ');

              if (address.isEmpty && city != null) {
                address = city;
              }

              geocodingSuccessful = true;
              AppLogger.log('Geocoded address: $address');
              break;
            }
          } on TimeoutException catch (e) {
            AppLogger.log('Geocoding attempt ${attempt + 1} timed out: $e');
            if (attempt < 2) {
              await Future.delayed(Duration(seconds: 1));
            }
          } catch (e) {
            AppLogger.log('Geocoding attempt ${attempt + 1} failed: $e');
            if (attempt < 2) {
              await Future.delayed(Duration(seconds: 1));
            } else {
              break;
            }
          }
        }
      } catch (e) {
        AppLogger.log('Geocoding completely failed: $e');
        // Don't return here - we still have coordinates
      }

      // Update UI with whatever we have
      if (geocodingSuccessful && address.isNotEmpty) {
        setState(() {
          locationController.text = address;
        });

        if (!mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location captured successfully',
        );
      } else {
        // Use coordinates as display, but we still have _locationPoint and _selectedState
        setState(() {
          locationController.text =
              'Lat: ${position!.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });

        if (!mounted) return;
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Location saved (GPS coordinates)',
        );
      }

      AppLogger.log('Final location point to send to backend: $_locationPoint');
      AppLogger.log('Final city to send to backend: $_selectedState');
    } on LocationServiceDisabledException catch (e) {
      AppLogger.log('Location services disabled: $e');
      setState(() {
        locationController.clear();
        _locationPoint = null;
      });

      if (!mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: 'Location services are disabled. Please enable GPS.',
      );
    } catch (e) {
      AppLogger.log('Error getting location: $e');
      setState(() {
        locationController.clear();
        _locationPoint = null;
        _selectedState = null;
      });

      if (!mounted) return;

      CustomFlushbar.showError(
        context: context,
        message: 'Failed to get location: ${e.toString()}',
      );
    }
  }

  Widget _buildContinueButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isEnabled = _isFormValid && !authProvider.isLoading;

        return GestureDetector(
          onTap: isEnabled
              ? () async {
                  if (_locationPoint == null || _locationPoint!.isEmpty) {
                    CustomFlushbar.showError(
                      context: context,
                      message: 'Please set your location first',
                    );
                    return;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  final phone =
                      prefs.getString('user_phone') ?? '+2341234567890';

                  final request = RegisterUserRequest(
                    email: emailController.text.trim(),
                    firstName: firstNameController.text.trim(),
                    middleName: middleNameController.text.trim().isEmpty
                        ? null
                        : middleNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phone,
                    dateOfBirth: dobController.text.trim(),
                    role: 'passenger',
                    city: _selectedState!,
                    location: _locationPoint!,
                    referralCode: referralController.text.trim().isEmpty
                        ? null
                        : referralController.text.trim(),
                    serviceType: 'taxi',
                  );

                  // Convert to Map
                  final requestMap = request.toJson();
                  AppLogger.log('Registration request: $requestMap');

                  // Pass the Map directly to the provider
                  final success = await authProvider.registerUserWithJson(
                    requestMap,
                  );

                  if (success) {
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
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
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: isEnabled
                  ? Color(ConstColors.mainColor)
                  : Colors.grey.shade300,
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
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(ConstColors.mainColor),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      String month = picked.month.toString().padLeft(2, '0');
      String day = picked.day.toString().padLeft(2, '0');
      controller.text = "$month/$day/${picked.year}";
      AppLogger.log('Date selected: ${controller.text}');
    }
  }
}
