import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
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
  final TextEditingController locationController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _checkToken();

    firstNameController.addListener(_updateButtonState);
    lastNameController.addListener(_updateButtonState);
    dobController.addListener(_updateButtonState);
    emailController.addListener(_updateButtonState);
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

    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    emailController.dispose();
    locationController.dispose();
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
                        onDateSelected: () =>
                            _selectDate(context, dobController),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Location', style: ConstTextStyles.fieldLabel),
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
                locationController.text = result;
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
                    locationController.text.isEmpty
                        ? 'States'
                        : locationController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: locationController.text.isEmpty
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

  Widget _buildContinueButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isEnabled = _isFormValid && !authProvider.isLoading;

        return GestureDetector(
          onTap: isEnabled
              ? () async {
                  final prefs = await SharedPreferences.getInstance();
                  final phone =
                      prefs.getString('user_phone') ?? '+2341234567890';

                  final request = RegisterUserRequest(
                    email: emailController.text.trim(),
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phone,
                    role: 'passenger',
                    location: null,
                  );

                  final requestJson = request.toJson();

                  requestJson['middle_name'] =
                      middleNameController.text.trim().isEmpty
                      ? ''
                      : middleNameController.text.trim();
                  requestJson['date_of_birth'] = dobController.text.trim();
                  requestJson['city'] = _selectedState!;
                  requestJson['service_type'] = 'taxi';

                  AppLogger.log('Registration request: $requestJson');

                  final success = await authProvider.registerUserWithJson(
                    requestJson,
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
