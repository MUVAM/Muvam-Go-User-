import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import '../widgets/editable_name_field.dart';

class EditFullNameScreen extends StatefulWidget {
  const EditFullNameScreen({super.key});

  @override
  _EditFullNameScreenState createState() => _EditFullNameScreenState();
}

class _EditFullNameScreenState extends State<EditFullNameScreen> {
  final TextEditingController firstNameController = TextEditingController(
    text: 'John',
  );
  final TextEditingController lastNameController = TextEditingController(
    text: 'Doe',
  );
  final TextEditingController emailController = TextEditingController(text: '');
  bool isFirstNameEditable = false;
  bool isLastNameEditable = false;
  bool isEmailEditable = false;

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
              EditableNameField(
                label: 'First name',
                controller: firstNameController,
                isEditable: isFirstNameEditable,
                onEditTap: () {
                  setState(() {
                    isFirstNameEditable = !isFirstNameEditable;
                  });
                },
              ),
              SizedBox(height: 20.h),
              EditableNameField(
                label: 'Last name',
                controller: lastNameController,
                isEditable: isLastNameEditable,
                onEditTap: () {
                  setState(() {
                    isLastNameEditable = !isLastNameEditable;
                  });
                },
              ),
              EditableNameField(
                label: 'Email address',
                controller: emailController,
                isEditable: isEmailEditable,
                onEditTap: () {
                  setState(() {
                    isEmailEditable = !isEmailEditable;
                  });
                },
              ),
              EditableNameField(
                label: 'Last name',
                controller: lastNameController,
                isEditable: isLastNameEditable,
                onEditTap: () {
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
}
