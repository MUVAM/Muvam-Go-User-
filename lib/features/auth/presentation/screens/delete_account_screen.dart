import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import '../widgets/delete_confirmation_sheet.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  DeleteAccountScreenState createState() => DeleteAccountScreenState();
}

class DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int? selectedReason;

  final List<String> reasons = [
    'I am no longer using my account',
    'It is not available in my state',
    'I want to change my phone number',
    'It is too expensive',
    'I just bought a car',
    'Others',
  ];

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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              Text(
                'We\'re really sorry to see you go 😢 Are you sure you want to delete your account? Once you confirm, your data will be gone.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: -0.41,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30.h),
              Expanded(
                child: ListView.builder(
                  itemCount: reasons.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedReason = index;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 15.h),
                        child: Row(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedReason == index
                                      ? Color(ConstColors.mainColor)
                                      : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: selectedReason == index
                                  ? Icon(
                                      Icons.check,
                                      size: 14.sp,
                                      color: Color(ConstColors.mainColor),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              child: Text(
                                reasons[index],
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.0,
                                  letterSpacing: -0.41,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 353.w,
                height: 47.h,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmationSheet(context),
                  child: Center(
                    child: Text(
                      'Delete my account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationSheet(BuildContext context) {
    DeleteConfirmationSheet.show(context, _deleteAccount);
  }

  void _deleteAccount() {
    Navigator.pop(context); // Close the bottom sheet
    Navigator.pop(context); // Go back to previous screen
  }
}
