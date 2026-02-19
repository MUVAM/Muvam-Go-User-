import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/presentation/screens/state_selection_screen.dart';
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

    // Initialize selected state
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
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        AppLogger.log('Profile image selected: ${pickedFile.path}');
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
    // Validate email
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

    AppLogger.log('Updating profile with:');
    AppLogger.log('Email: ${emailController.text.trim()}');
    AppLogger.log('State: $_selectedState');
    AppLogger.log('Profile Photo: ${_profileImage?.path ?? "No change"}');

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
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
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
                                      : Consumer<UserProfileProvider>(
                                          builder: (context, profileProvider, child) {
                                            return (profileProvider
                                                        .userProfilePhoto
                                                        .isNotEmpty &&
                                                    profileProvider
                                                            .userProfilePhoto !=
                                                        '')
                                                ? ClipOval(
                                                    child: Image.network(
                                                      profileProvider
                                                          .userProfilePhoto,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Container(
                                                              color: Color(
                                                                0xFFE0E0E0,
                                                              ),
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 40.sp,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            );
                                                          },
                                                    ),
                                                  )
                                                : Container(
                                                    color: Color(0xFFE0E0E0),
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
                                      color: Color(
                                        ConstColors.mainColor,
                                      ).withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
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
                          child: Text(
                            'Tap to change photo',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
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
                        GestureDetector(
                          onTap: null,
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
                          readOnly: false,
                        ),
                        SizedBox(height: 16.h),
                        _buildStateField(),
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
                        borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildStateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
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
              AppLogger.log('User selected state: $_selectedState');
            }
          },
          child: Container(
            width: double.infinity,
            height: 50.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: Color(0xFFE0E0E0), width: 1),
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
                    width: 12.w,
                    height: 12.h,
                    fit: BoxFit.scaleDown,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
