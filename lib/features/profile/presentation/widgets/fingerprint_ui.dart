import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';

class FingerprintUI extends StatelessWidget {
  final bool isAuthenticating;
  final bool authenticationSuccessful;

  const FingerprintUI({
    super.key,
    required this.isAuthenticating,
    required this.authenticationSuccessful,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.w,
      height: 200.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            authenticationSuccessful
                ? 'assets/images/fingerGreen.png'
                : 'assets/images/fingerGrey.png',
            width: 150.w,
            height: 150.h,
            fit: BoxFit.contain,
          ),
          if (isAuthenticating)
            Container(
              width: 200.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: AppColors.kWhiteColor.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 50.w,
                  height: 50.h,
                  child: CircularProgressIndicator(
                    color: AppColors.kMainColor,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
