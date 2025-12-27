import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';

import '../widgets/logout_sheet.dart';
import '../widgets/profile_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );

    // Fetch profile from API
    await profileProvider.fetchUserProfile();

    // Populate controllers with profile data
    if (profileProvider.userProfile != null) {
      firstNameController.text = profileProvider.userFirstName;
      middleNameController.text = profileProvider.userMiddleName;
      lastNameController.text = profileProvider.userLastName;
      emailController.text = profileProvider.userEmail;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
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
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          ConstImages.back,
                          width: 30.w,
                          height: 30.h,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'My Account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () => _navigateToEditProfile(context),
                  child: Stack(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (profileProvider.userProfilePhoto.isNotEmpty &&
                                  profileProvider.userProfilePhoto != '')
                            ? ClipOval(
                                child: Image.network(
                                  profileProvider.userProfilePhoto,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      ConstImages.avatar,
                                      width: 80.w,
                                      height: 80.h,
                                    );
                                  },
                                ),
                              )
                            : Image.asset(
                                ConstImages.avatar,
                                width: 80.w,
                                height: 80.h,
                              ),
                      ),
                      Positioned(
                        top: 6.h,
                        left: 51.w,
                        child: Container(
                          width: 18.w,
                          height: 18.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileField(
                          label: 'Full name',
                          value: profileProvider.userName,
                          hasEdit: true,
                          onEditTap: () => _navigateToEditProfile(context),
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Phone number',
                          value: profileProvider.userPhone.isNotEmpty
                              ? profileProvider.userPhone
                              : 'Not set',
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Date of birth',
                          value: profileProvider.userDateOfBirth.isNotEmpty
                              ? profileProvider.userDateOfBirth
                              : 'Not set',
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'Email address',
                          value: profileProvider.userEmail.isNotEmpty
                              ? profileProvider.userEmail
                              : 'Not set',
                        ),
                        SizedBox(height: 15.h),
                        ProfileField(
                          label: 'City',
                          value: profileProvider.userCity.isNotEmpty
                              ? profileProvider.userCity
                              : 'Not set',
                        ),
                        SizedBox(height: 40.h),
                        Container(
                          width: 353.w,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: GestureDetector(
                            onTap: () => _showLogoutSheet(context),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeleteAccountScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Delete Account',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
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

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => LogoutSheet(
        onLogout: () async {
          final profileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          await profileProvider.clearProfile();
          await authProvider.logout();

          // Close the logout sheet
          Navigator.pop(context);

          // Navigate to onboarding screen and clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        },
        onGoBack: () => Navigator.pop(context),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
