import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/auth/presentation/widgets/account_text_field.dart';
import 'package:muvam/features/auth/presentation/widgets/location_field.dart';
import 'package:muvam/features/auth/presentation/widgets/state_field.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    for (final c in [
      firstNameController,
      lastNameController,
      dobController,
      emailController,
      stateController,
    ]) {
      c.addListener(_updateButtonState);
    }
  }

  void _updateButtonState() => setState(() {});

  bool get _isFormValid =>
      firstNameController.text.isNotEmpty &&
      lastNameController.text.isNotEmpty &&
      dobController.text.isNotEmpty &&
      emailController.text.isNotEmpty &&
      _selectedState != null;

  void _checkToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.checkTokenValidity();
    AppLogger.log('Token valid in create account: $token');
    final prefs = await SharedPreferences.getInstance();
    AppLogger.log('Stored token: ${prefs.getString('auth_token')}');
  }

  @override
  void dispose() {
    for (final c in [
      firstNameController,
      middleNameController,
      lastNameController,
      dobController,
      emailController,
      stateController,
      referralController,
      locationController,
    ]) {
      c.removeListener(_updateButtonState);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.kMainColor,
            onPrimary: AppColors.kWhiteColor,
            surface: AppColors.kWhiteColor,
            onSurface: AppColors.kBlackColor,
          ),
          dialogBackgroundColor: AppColors.kWhiteColor,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 25.h),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Create Account',
                    center: true,
                    isTextWidget: true,
                  ),
                  SizedBox(height: 5.h),
                  MuvamTexts.bodySmall12(
                    context,
                    text:
                        'Please enter your correct details as it is\non your government issued document.',
                    center: true,
                    isTextWidget: true,
                    color: AppColors.kSubtitleColor,
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
                        backgroundColor: AppColors.kFormFieldColor.value,
                        hintText: 'Enter your first name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Middle name (Optional)',
                        controller: middleNameController,
                        backgroundColor: AppColors.kFormFieldColor.value,
                        hintText: 'Enter your middle name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Last name',
                        controller: lastNameController,
                        backgroundColor: AppColors.kFormFieldColor.value,
                        hintText: 'Enter your last name',
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Date of birth',
                        controller: dobController,
                        backgroundColor: AppColors.kFormFieldColor.value,
                        isDateField: true,
                        hintText: 'MM/DD/YYYY',
                        onDateSelected: () =>
                            _selectDate(context, dobController),
                      ),
                      SizedBox(height: 20.h),
                      StateField(
                        controller: stateController,
                        onStateSelected: (state) {
                          setState(() {
                            _selectedState = state;
                          });
                        },
                      ),
                      SizedBox(height: 20.h),
                      LocationField(
                        controller: locationController,
                        onLocationChanged: (point) {
                          setState(() {
                            _locationPoint = point;
                          });
                        },
                      ),
                      SizedBox(height: 20.h),
                      AccountTextField(
                        label: 'Referral code (Optional)',
                        controller: referralController,
                        backgroundColor: AppColors.kFormFieldColor.value,
                        hintText: 'Enter referral code if you have one',
                      ),
                      SizedBox(height: 40.h),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final isEnabled =
                              _isFormValid &&
                              !authProvider.isLoading &&
                              _locationPoint != null;
                          return GestureDetector(
                            onTap: isEnabled
                                ? () async {
                                    if (_locationPoint == null ||
                                        _locationPoint!.isEmpty) {
                                      CustomFlushbar.showError(
                                        context: context,
                                        message:
                                            'Please set your location first',
                                      );
                                      return;
                                    }

                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final phone =
                                        prefs.getString('user_phone') ??
                                        '+2341234567890';

                                    final request = RegisterUserRequest(
                                      email: emailController.text.trim(),
                                      firstName: firstNameController.text
                                          .trim(),
                                      middleName:
                                          middleNameController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : middleNameController.text.trim(),
                                      lastName: lastNameController.text.trim(),
                                      phone: phone,
                                      dateOfBirth: dobController.text.trim(),
                                      role: 'passenger',
                                      city: _selectedState!,
                                      location: _locationPoint!,
                                      referralCode:
                                          referralController.text.trim().isEmpty
                                          ? null
                                          : referralController.text.trim(),
                                      serviceType: 'taxi',
                                    );

                                    final requestMap = request.toJson();
                                    AppLogger.log(
                                      'Registration request: $requestMap',
                                    );

                                    final success = await authProvider
                                        .registerUserWithJson(requestMap);
                                    if (!mounted) return;

                                    if (success) {
                                      context.goNamed(AppRoutes.home.name);
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
                              width: double.infinity,
                              height: 47.h,
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? AppColors.kMainColor
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Center(
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: const CircularProgressIndicator(
                                          color: AppColors.kWhiteColor,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : MuvamTexts.button16(
                                        context,
                                        text: 'Continue',
                                        isTextWidget: true,
                                        color: AppColors.kWhiteColor,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                      DeviceBottomPadding(),
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
}
