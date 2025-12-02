import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EditProfileSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: onPickImage,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: profileImage != null
                    ? ClipOval(
                        child: Image.file(profileImage!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.camera_alt, size: 30.sp),
              ),
            ),
            SizedBox(height: 20.h),
            _buildEditField('First Name', firstNameController),
            SizedBox(height: 15.h),
            _buildEditField('Middle Name', middleNameController),
            SizedBox(height: 15.h),
            _buildEditField('Last Name', lastNameController),
            SizedBox(height: 15.h),
            _buildEditField('Email', emailController),
            SizedBox(height: 20.h),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return GestureDetector(
                  onTap: !authProvider.isLoading
                      ? () async {
                          final request = CompleteProfileRequest(
                            firstName: firstNameController.text,
                            middleName: middleNameController.text.isEmpty
                                ? null
                                : middleNameController.text,
                            lastName: lastNameController.text,
                            email: emailController.text,
                            profilePhotoPath: profileImage?.path,
                          );

                          final success = await authProvider.completeProfile(
                            request,
                          );

                          if (success) {
                            Navigator.pop(context);
                            onUpdate();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Profile updated successfully'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authProvider.errorMessage ??
                                      'Failed to update profile',
                                ),
                                backgroundColor: Colors.red,
                              ),
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
                          ? CircularProgressIndicator(color: Colors.white)
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
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
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
}
