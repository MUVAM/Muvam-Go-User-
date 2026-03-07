import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/features/profile/presentation/widgets/corner_guides.dart';

class FaceUnlockUI extends StatelessWidget {
  final bool isAuthenticating;
  final bool authenticationSuccessful;

  const FaceUnlockUI({
    super.key,
    required this.isAuthenticating,
    required this.authenticationSuccessful,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250.w,
      height: 300.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200.w,
            height: 260.h,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(130.r),
              border: Border.all(
                color: authenticationSuccessful
                    ? Colors.green
                    : isAuthenticating
                    ? AppColors.kMainColor
                    : Colors.grey.shade400,
                width: 4.w,
              ),
            ),
          ),
          CornerGuides(
            isAuthenticating: isAuthenticating,
            authenticationSuccessful: authenticationSuccessful,
          ),
          if (!isAuthenticating && !authenticationSuccessful)
            Icon(Icons.face, size: 80.sp, color: Colors.grey.shade300),
          if (authenticationSuccessful)
            Container(
              width: 80.w,
              height: 80.h,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 50.sp,
                color: AppColors.kWhiteColor,
              ),
            ),
          if (isAuthenticating)
            SizedBox(
              width: 60.w,
              height: 60.h,
              child: CircularProgressIndicator(
                color: AppColors.kMainColor,
                strokeWidth: 4,
              ),
            ),
        ],
      ),
    );
  }
}
