import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/core/utils/extension.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/profile/presentation/widgets/edit_field.dart';
import 'package:muvam/features/profile/presentation/widgets/profile_image_picker.dart';
import 'package:muvam/features/profile/presentation/widgets/state_field_sheet.dart';
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
              MuvamTexts.titleMedium18(
                context,
                text: 'Edit Profile',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 20.h),
              ProfileImagePicker(
                profileImage: widget.profileImage,
                onTap: widget.onPickImage,
              ),
              SizedBox(height: 20.h),
              EditField(
                label: 'First Name',
                controller: widget.firstNameController,
                readOnly: true,
              ),
              SizedBox(height: 15.h),
              EditField(
                label: 'Middle Name',
                controller: widget.middleNameController,
                readOnly: true,
              ),
              SizedBox(height: 15.h),
              EditField(
                label: 'Last Name',
                controller: widget.lastNameController,
                readOnly: true,
              ),
              SizedBox(height: 15.h),
              EditField(
                label: 'Email',
                controller: widget.emailController,
                readOnly: false,
              ),
              SizedBox(height: 15.h),
              StateFieldSheet(
                controller: _stateController,
                selectedState: _selectedState,
                onStateSelected: (state) {
                  setState(() {
                    _selectedState = state;
                    _stateController.text = state;
                  });
                },
              ),
              SizedBox(height: 20.h),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return GestureDetector(
                    onTap: !authProvider.isLoading
                        ? () async {
                            if (widget.emailController.text.trim().isEmpty) {
                              CustomFlushbar.showError(
                                context: context,
                                message: 'Please enter email address',
                              );
                              return;
                            }
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
                              context.pop();
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
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
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
                                text: 'Update Profile',
                                isTextWidget: true,
                                color: AppColors.kWhiteColor,
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
}
