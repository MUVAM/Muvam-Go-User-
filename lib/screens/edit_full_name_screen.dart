import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';

class EditFullNameScreen extends StatefulWidget {
  @override
  _EditFullNameScreenState createState() => _EditFullNameScreenState();
}

class _EditFullNameScreenState extends State<EditFullNameScreen> {
  final TextEditingController firstNameController = TextEditingController(text: 'John');
  final TextEditingController lastNameController = TextEditingController(text: 'Doe');
  bool isFirstNameEditable = false;
  bool isLastNameEditable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 60.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Full name',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30.h),
              _buildEditableField(
                'First name',
                firstNameController,
                isFirstNameEditable,
                () {
                  setState(() {
                    isFirstNameEditable = !isFirstNameEditable;
                  });
                },
              ),
              SizedBox(height: 20.h),
              _buildEditableField(
                'Last name',
                lastNameController,
                isLastNameEditable,
                () {
                  setState(() {
                    isLastNameEditable = !isLastNameEditable;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditable, VoidCallback onEditTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Color(0xFFB1B1B1),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 47.h,
          decoration: BoxDecoration(
            color: Color(0xFFF7F9F8),
            borderRadius: BorderRadius.circular(3.r),
          ),
          padding: EdgeInsets.only(
            top: 15.h,
            right: 14.w,
            bottom: 15.h,
            left: 14.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: controller,
                    enabled: isEditable,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Color(ConstColors.mainColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}