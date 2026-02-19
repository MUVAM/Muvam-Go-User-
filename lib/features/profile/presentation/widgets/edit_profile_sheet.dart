import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/auth/presentation/screens/state_selection_screen.dart';
import 'package:provider/provider.dart';

class EditProfileSheet extends StatefulWidget {
  final File? profileImage;
  final Future<void> Function() onPickImage;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final VoidCallback onUpdate;

  const EditProfileSheet({
    super.key,
    required this.profileImage,
    required this.onPickImage,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.emailController,
    required this.onUpdate,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final TextEditingController _stateController = TextEditingController();
  String? _selectedState;

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: widget.onPickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: widget.profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                widget.profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.camera_alt, size: 30.sp),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor).withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // First Name - Read Only (Disabled)
              _buildReadOnlyField('First Name', widget.firstNameController),
              SizedBox(height: 15.h),
              // Middle Name - Read Only (Disabled)
              _buildReadOnlyField('Middle Name', widget.middleNameController),
              SizedBox(height: 15.h),
              // Last Name - Read Only (Disabled)
              _buildReadOnlyField('Last Name', widget.lastNameController),
              SizedBox(height: 15.h),
              // Email - Editable
              _buildEditField('Email', widget.emailController),
              SizedBox(height: 15.h),
              // State/City - Editable with StateSelectionScreen
              _buildStateField(),
              SizedBox(height: 20.h),
              // Update Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return GestureDetector(
                    onTap: !authProvider.isLoading
                        ? () async {
                            // Validate email
                            if (widget.emailController.text.trim().isEmpty) {
                              CustomFlushbar.showError(
                                context: context,
                                message: 'Please enter email address',
                              );
                              return;
                            }

                            // Validate email format
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegex.hasMatch(
                              widget.emailController.text.trim(),
                            )) {
                              CustomFlushbar.showError(
                                context: context,
                                message: 'Please enter a valid email address',
                              );
                              return;
                            }

                            final request = CompleteProfileRequest(
                              firstName: widget.firstNameController.text,
                              middleName:
                                  widget.middleNameController.text.isEmpty
                                  ? null
                                  : widget.middleNameController.text,
                              lastName: widget.lastNameController.text,
                              email: widget.emailController.text.trim(),
                              city: _selectedState,
                              profilePhotoPath: widget.profileImage?.path,
                            );

                            final success = await authProvider.completeProfile(
                              request,
                            );

                            if (success) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              widget.onUpdate();
                              CustomFlushbar.showSuccess(
                                context: context,
                                message: 'Profile updated successfully',
                              );
                            } else {
                              if (!mounted) return;
                              CustomFlushbar.showError(
                                context: context,
                                message:
                                    authProvider.errorMessage ??
                                    'Failed to update profile',
                              );
                            }
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: authProvider.isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Update Profile',
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
            ],
          ),
        ),
      ),
    );
  }

  // Editable field widget
  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Color(ConstColors.mainColor)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
        ),
      ],
    );
  }

  // Read-only (disabled) field widget
  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          enabled: false,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
        ),
      ],
    );
  }

  // State selection field widget
  Widget _buildStateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5.h),
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
                _stateController.text = result;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _stateController.text.isEmpty
                        ? 'Select State'
                        : _stateController.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: _stateController.text.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 12.w,
                    height: 12.h,
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
}
