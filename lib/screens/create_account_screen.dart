import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../providers/auth_provider.dart';
import '../models/auth_models.dart';
import 'home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  String? _locationPoint;

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
                _buildTextField(
                  'First Name',
                  firstNameController,
                  ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                _buildTextField(
                  'Middle Name (Optional)',
                  middleNameController,
                  ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                _buildTextField(
                  'Last Name',
                  lastNameController,
                  ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                _buildTextField(
                  'Email Address',
                  emailController,
                  ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                _buildLocationField(),
                SizedBox(height: 20.h),
                _buildTextField(
                  'Referral Code (Optional)',
                  referralController,
                  ConstColors.formFieldColor,
                ),
                SizedBox(height: 40.h),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return GestureDetector(
                      onTap: !authProvider.isLoading
                          ? () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final phone =
                                  prefs.getString('user_phone') ??
                                  '+2341234567890';

                              final request = RegisterUserRequest(
                                email: emailController.text,
                                firstName: firstNameController.text,
                                lastName: lastNameController.text,
                                phone: phone,
                                role: 'passenger',
                                location: _locationPoint,
                              );

                              final requestJson = request.toJson();
                              requestJson['service_type'] =
                                  'taxi'; // Force add service_type
                              AppLogger.log(
                                'Registration request from screen: $requestJson',
                              );
                              AppLogger.log(
                                'Service type in request: ${requestJson['service_type']}',
                              );

                              final success = await authProvider.registerUser(
                                request,
                              );

                              if (success) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              } else {
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
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    int backgroundColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ConstTextStyles.fieldLabel),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(backgroundColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: controller,
            style: ConstTextStyles.inputText,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 15.h,
              ),
            ),
          ),
        ),
      ],
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
            color: Color(ConstColors.formFieldColor),
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CustomFlushbar.showError(
            context: context,
            message: 'Location permission denied',
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
        locationController.text = address;
        _locationPoint = 'POINT(${position.longitude} ${position.latitude})';
        AppLogger.log('Location Point: $_locationPoint');
      }
    } catch (e) {
      AppLogger.log('Error getting location: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to get location',
      );
    }
  }
}
