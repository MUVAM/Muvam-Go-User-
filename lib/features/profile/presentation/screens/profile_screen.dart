import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/screens/app_lock_settings_screen.dart';
import 'package:muvam/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  void _loadUserProfile() async {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );

    await profileProvider.fetchUserProfile();

    if (profileProvider.userProfile != null) {
      firstNameController.text = profileProvider.userFirstName;
      middleNameController.text = profileProvider.userMiddleName;
      lastNameController.text = profileProvider.userLastName;
      emailController.text = profileProvider.userEmail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading && profileProvider.userProfile == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(ConstColors.mainColor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
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
                            size: 20.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'My account',
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
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToEditProfile(context),
                          child: Stack(
                            children: [
                              Container(
                                width: 100.w,
                                height: 100.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFE0E0E0),
                                ),
                                child: _profileImage != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (profileProvider
                                              .userProfilePhoto
                                              .isNotEmpty &&
                                          profileProvider.userProfilePhoto !=
                                              '')
                                    ? ClipOval(
                                        child: Image.network(
                                          profileProvider.userProfilePhoto,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Color(0xFFE0E0E0),
                                                );
                                              },
                                        ),
                                      )
                                    : Container(),
                              ),
                              Positioned(
                                bottom: 60,
                                right: 0,
                                child: Container(
                                  width: 24.w,
                                  height: 24.h,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      ConstColors.mainColor,
                                    ).withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProfileField(
                                label: 'Full name',
                                value: profileProvider.userName,
                                hasEdit: false,
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'Phone number',
                                value: profileProvider.userPhone.isNotEmpty
                                    ? profileProvider.userPhone
                                    : 'Not set',
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'Date of birth',
                                value:
                                    profileProvider.userDateOfBirth.isNotEmpty
                                    ? profileProvider.userDateOfBirth
                                    : 'Not set',
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'Email address',
                                value: profileProvider.userEmail.isNotEmpty
                                    ? profileProvider.userEmail
                                    : 'Not set',
                              ),
                              SizedBox(height: 16.h),
                              ProfileField(
                                label: 'State',
                                value: profileProvider.userCity.isNotEmpty
                                    ? profileProvider.userCity
                                    : 'Not set',
                              ),
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AppLockSettingsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10.sp),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48.w,
                                        height: 48.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(
                                            ConstColors.mainColor,
                                          ).withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          color: Color(ConstColors.mainColor),
                                          size: 28.sp,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Set up biometrics',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              'Secure your app with fingerprint \nor face unlock',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF9E9E9E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: () => _navigateToEditProfile(context),
                                child: Container(
                                  width: double.infinity,
                                  height: 47.h,
                                  decoration: BoxDecoration(
                                    color: Color(ConstColors.mainColor),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Edit profile',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen()),
    );
  }
}
