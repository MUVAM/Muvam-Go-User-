import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class StopMarkerWidget extends StatelessWidget {
  final String? stopAddress;

  const StopMarkerWidget({super.key, this.stopAddress});

  @override
  Widget build(BuildContext context) {
    String stopText = stopAddress ?? 'Stop';

    return Container(
      width: 200.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stop_circle, color: AppColors.kWhiteColor, size: 16.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: MuvamTexts.bodySmall12(
              context,
              text: stopText,
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kWhiteColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
