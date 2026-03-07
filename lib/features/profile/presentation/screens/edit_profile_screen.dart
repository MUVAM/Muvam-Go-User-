import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/widgets/edit_profile_text_field.dart';
import 'package:muvam/features/profile/presentation/widgets/state_field.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
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

  String? _selectedState;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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
    _selectedState = profileProvider.userCity;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      AppLogger.log('Error picking image: $e');
      if (!mounted) return;
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to pick image',
      );
    }
  }

  Future<void> _saveProfile() async {
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
    final nameParts = fullNameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final success = await provider.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      email: emailController.text.trim(),
      dateOfBirth: dobController.text.trim(),
      city: _selectedState,
      profilePhotoPath: _profileImage?.path,
    );

    if (!mounted) return;

    if (success) {
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Profile updated successfully',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.goNamed(AppRoutes.home.name);
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
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
                            text: 'Edit profile',
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
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100.w,
                                  height: 100.h,
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
                                      : Consumer<UserProfileProvider>(
                                          builder: (context, p, _) {
                                            return p.userProfilePhoto.isNotEmpty
                                                ? ClipOval(
                                                    child: Image.network(
                                                      p.userProfilePhoto,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            color: const Color(
                                                              0xFFE0E0E0,
                                                            ),
                                                            child: Icon(
                                                              Icons.person,
                                                              size: 40.sp,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                    ),
                                                  )
                                                : Container(
                                                    color: const Color(
                                                      0xFFE0E0E0,
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 40.sp,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                          },
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32.w,
                                    height: 32.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.kMainColor.withOpacity(
                                        0.9,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.kWhiteColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: AppColors.kWhiteColor,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Center(
                          child: MuvamTexts.bodySmall12(
                            context,
                            text: 'Tap to change photo',
                            isTextWidget: true,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 32.h),
                        EditProfileTextField(
                          label: 'Full name',
                          controller: fullNameController,
                          readOnly: true,
                        ),
                        SizedBox(height: 16.h),
                        EditProfileTextField(
                          label: 'Phone number',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          readOnly: true,
                        ),
                        SizedBox(height: 16.h),
                        AbsorbPointer(
                          child: EditProfileTextField(
                            label: 'Date of birth',
                            controller: dobController,
                            hintText: 'MM/DD/YYYY',
                            readOnly: true,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        EditProfileTextField(
                          label: 'Email address',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: false,
                        ),
                        SizedBox(height: 16.h),
                        StateField(
                          controller: stateController,
                          selectedState: _selectedState,
                          onStateSelected: (state) {
                            setState(() {
                              _selectedState = state;
                              stateController.text = state;
                            });
                          },
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: GestureDetector(
                    onTap: provider.isUpdating ? null : _saveProfile,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: provider.isUpdating
                            ? Colors.grey
                            : AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: provider.isUpdating
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  color: AppColors.kWhiteColor,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : MuvamTexts.button16(
                                context,
                                text: 'Save changes',
                                isTextWidget: true,
                                color: AppColors.kWhiteColor,
                              ),
                      ),
                    ),
                  ),
                ),
                DeviceBottomPadding(),
              ],
            );
          },
        ),
      ),
    );
  }
}
