import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserProfile());
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
          return AppScaffold(
            backgroundColor: AppColors.kWhiteColor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.kMainColor),
            ),
          );
        }

        return AppScaffold(
          backgroundColor: AppColors.kWhiteColor,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.kBlackColor,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: MuvamTexts.titleLarge22(
                            context,
                            text: 'My account',
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
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
                          onTap: () =>
                              context.pushNamed(AppRoutes.editProfile.name),
                          child: Stack(
                            children: [
                              Container(
                                width: 80.w,
                                height: 80.h,
                                decoration: const BoxDecoration(
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
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: const Color(0xFFE0E0E0),
                                              ),
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
                                    color: AppColors.kMainColor.withValues(
                                      alpha: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: AppColors.kWhiteColor,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacings.k20,
                          ),
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
                                  context.pushNamed(
                                    AppRoutes.appLockSettings.name,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10.sp),
                                  decoration: BoxDecoration(
                                    color: AppColors.kWhiteColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48.w,
                                        height: 47.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.kMainColor
                                              .withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          color: AppColors.kMainColor,
                                          size: 28.sp,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MuvamTexts.bodyMedium14(
                                              context,
                                              text: 'Set up biometrics',
                                              isTextWidget: true,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            SizedBox(height: 2.h),
                                            MuvamTexts.bodySmall12(
                                              context,
                                              text:
                                                  'Secure your app with fingerprint \nor face unlock',
                                              isTextWidget: true,
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: () => context.pushNamed(
                                  AppRoutes.editProfile.name,
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: double.infinity,
                                  height: 47.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.kMainColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Center(
                                    child: MuvamTexts.button16(
                                      context,
                                      text: 'Edit profile',
                                      isTextWidget: true,
                                      color: AppColors.kWhiteColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 5.h),
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    AppRoutes.deleteAccount.name,
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 16.h,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        ConstImages.bin,
                                        width: 24.w,
                                        height: 24.h,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(width: 16.w),
                                      MuvamTexts.titleMedium18(
                                        context,
                                        text: 'Delete account',
                                        isTextWidget: true,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFEF5350),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
}
