import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class DropoffMarkerWidget extends StatelessWidget {
  final String? destAddress;
  final String toText;

  const DropoffMarkerWidget({
    super.key,
    this.destAddress,
    required this.toText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 242.w,
      height: 48.h,
      padding: EdgeInsets.fromLTRB(10.w, 7.h, 10.w, 7.h),
      decoration: BoxDecoration(
        color: AppColors.kWhiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: Color(ConstColors.mainColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.kWhiteColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MuvamTexts.bodySmall12(
                  context,
                  text: 'Drop off',
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                MuvamTexts.bodyMedium14(
                  context,
                  text:
                      destAddress ??
                      (toText.isNotEmpty ? toText : 'Destination'),
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
