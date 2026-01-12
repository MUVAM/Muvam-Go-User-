import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/widgets/edit_profile_text_field.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController emailController;
  late TextEditingController stateController;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );

    fullNameController = TextEditingController(text: profileProvider.userName);
    phoneController = TextEditingController(text: profileProvider.userPhone);
    dobController = TextEditingController(
      text: profileProvider.userDateOfBirth,
    );
    emailController = TextEditingController(text: profileProvider.userEmail);
    stateController = TextEditingController(text: profileProvider.userCity);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime(2000);

    if (dobController.text.isNotEmpty) {
      try {
        final parts = dobController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      } catch (e) {
        AppLogger.log('Error parsing date: $e');
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
      dobController.text = "$month/$day/${picked.year}";
      AppLogger.log('Date selected: ${dobController.text}');
    }
  }

  Future<void> _saveProfile() async {
    if (fullNameController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter full name',
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter email address',
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter a valid email address',
      );
      return;
    }

    final provider = context.read<UserProfileProvider>();

    // Split full name into first and last name
    final nameParts = fullNameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final success = await provider.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      email: emailController.text.trim(),
      dateOfBirth: dobController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Profile updated successfully',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        }
      });
    } else {
      CustomFlushbar.showError(
        context: context,
        message: provider.errorMessage ?? 'Failed to update profile',
      );
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    emailController.dispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<UserProfileProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Edit profile',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EditProfileTextField(
                          label: 'Full name',
                          controller: fullNameController,
                        ),
                        SizedBox(height: 16.h),
                        EditProfileTextField(
                          label: 'Phone number',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          readOnly: true,
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: EditProfileTextField(
                              label: 'Date of birth',
                              controller: dobController,
                              hintText: 'MM/DD/YYYY',
                              readOnly: true,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        EditProfileTextField(
                          label: 'Email address',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16.h),
                        EditProfileTextField(
                          label: 'State',
                          controller: stateController,
                          readOnly: true,
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: GestureDetector(
                    onTap: provider.isUpdating ? null : _saveProfile,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: provider.isUpdating
                            ? Colors.grey
                            : Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: provider.isUpdating
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Save changes',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
