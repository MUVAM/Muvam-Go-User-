import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/profile_field.dart';
import '../widgets/logout_sheet.dart';

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
    _loadUserData();
  }

  void _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUserData();
    final userData = authProvider.userData;

    if (userData['first_name'] != null)
      firstNameController.text = userData['first_name']!;
    if (userData['last_name'] != null)
      lastNameController.text = userData['last_name']!;
    if (userData['email'] != null) emailController.text = userData['email']!;
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
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'My Account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
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
            SizedBox(height: 40.h),
            GestureDetector(
              onTap: () => _showEditProfileSheet(context),
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
                      child: Icon(Icons.add, color: Colors.white, size: 12.sp),
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
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final userData = authProvider.userData;
                        return Column(
                          children: [
                            ProfileField(
                              label: 'Full name',
                              value:
                                  '${userData['first_name'] ?? 'Not set'} ${userData['last_name'] ?? ''}',
                              hasEdit: true,
                              onEditTap: () => _showEditProfileSheet(context),
                            ),
                            SizedBox(height: 15.h),
                            ProfileField(
                              label: 'Phone number',
                              value: '+234 123 456 7890',
                            ),
                            SizedBox(height: 15.h),
                            ProfileField(
                              label: 'Date of birth',
                              value: 'January 1, 1990',
                            ),
                            SizedBox(height: 15.h),
                            ProfileField(
                              label: 'Email address',
                              value: userData['email'] ?? 'Not set',
                            ),
                            SizedBox(height: 15.h),
                            ProfileField(label: 'State', value: 'Lagos'),
                          ],
                        );
                      },
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
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => EditProfileSheet(
        profileImage: _profileImage,
        onPickImage: _pickImage,
        firstNameController: firstNameController,
        middleNameController: middleNameController,
        lastNameController: lastNameController,
        emailController: emailController,
        onUpdate: () => setState(() {}),
      ),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => LogoutSheet(
        onLogout: () {
          // Add logout logic here
          Navigator.pop(context);
        },
        onGoBack: () => Navigator.pop(context),
      ),
    );
  }
}
