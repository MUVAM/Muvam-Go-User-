import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/wallet/presentation/screens/account_created_screen.dart';

class GetAccountScreen extends StatefulWidget {
  const GetAccountScreen({super.key});

  @override
  State<GetAccountScreen> createState() => _GetAccountScreenState();
}

class _GetAccountScreenState extends State<GetAccountScreen> {
  final TextEditingController bvnController = TextEditingController();
  bool isLoading = false;
  bool showError = false;

  bool _isFormValid() {
    return bvnController.text.length == 10;
  }

  void _handleVerify() async {
    if (!_isFormValid()) return;

    setState(() {
      isLoading = true;
      showError = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AccountCreatedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 24.w,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get an account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Enter your BVN to create your \npersonal wallet',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(height: 40.h),
              Text(
                'Bank Verification Number (BVN)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: bvnController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                onChanged: (value) => setState(() {
                  showError = false;
                }),
                decoration: InputDecoration(
                  hintText: 'Enter your BVN',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Color(ConstColors.formFieldColor),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                ),
              ),
              if (showError) ...[
                SizedBox(height: 8.h),
                Text(
                  'Please enter your correct BVN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.red,
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note: We only collect your BVN to generate a wallet account for you and it is totally optional.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(ConstColors.mainColor),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your bvn is totally safe and will never be \ndisclosed.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(ConstColors.mainColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isFormValid() && !isLoading ? _handleVerify : null,
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _isFormValid() && !isLoading
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Verify',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
