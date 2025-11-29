import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import 'home_screen.dart';

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
                _buildTextField('First Name', firstNameController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Middle Name (Optional)', middleNameController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Last Name', lastNameController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Date of Birth', dobController, ConstColors.formFieldColor, isDateField: true),
                SizedBox(height: 20.h),
                _buildTextField('Email Address', emailController, ConstColors.formFieldColor),
                SizedBox(height: 20.h),
                _buildTextField('Location', locationController, ConstColors.locationFieldColor, hasDropdown: true),
                SizedBox(height: 20.h),
                _buildTextField('Referral Code (Optional)', referralController, ConstColors.formFieldColor),
                SizedBox(height: 40.h),
                GestureDetector(
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
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, int backgroundColor, {bool isDateField = false, bool hasDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ConstTextStyles.fieldLabel,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(backgroundColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isDateField,
                  style: ConstTextStyles.inputText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  ),
                  onTap: isDateField ? () => _selectDate(context, controller) : null,
                ),
              ),
              if (hasDropdown)
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(Icons.arrow_drop_down, size: 20.sp),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
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