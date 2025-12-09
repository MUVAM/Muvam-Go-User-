import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/features/auth/presentation/widgets/account_text_field.dart';
import 'package:muvam/features/home/presentation/screens/home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController referralController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Text(
                  'Create Account',
                  style: ConstTextStyles.createAccountTitle,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please enter your correct details as it is on your government issued document.',
                  style: ConstTextStyles.createAccountSubtitle.copyWith(
                    color: Color(ConstColors.subtitleColor),
                  ),
                ),
                SizedBox(height: 30.h),
                AccountTextField(
                  label: 'First Name',
                  controller: firstNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Middle Name (Optional)',
                  controller: middleNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Last Name',
                  controller: lastNameController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Date of Birth',
                  controller: dobController,
                  backgroundColor: ConstColors.formFieldColor,
                  isDateField: true,
                  onDateSelected: () => _selectDate(context, dobController),
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Email Address',
                  controller: emailController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Location',
                  controller: locationController,
                  backgroundColor: ConstColors.locationFieldColor,
                  hasDropdown: true,
                ),
                SizedBox(height: 20.h),
                AccountTextField(
                  label: 'Referral Code (Optional)',
                  controller: referralController,
                  backgroundColor: ConstColors.formFieldColor,
                ),
                SizedBox(height: 40.h),
                _buildContinueButton(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
      child: Container(
        width: 353.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: Color(ConstColors.mainColor),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }
}
