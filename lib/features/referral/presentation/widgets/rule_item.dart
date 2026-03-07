import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class RuleItem extends StatelessWidget {
  final String number;
  final String text;

  const RuleItem({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          decoration: const BoxDecoration(
            color: AppColors.kMainColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: MuvamTexts.bodySmall12(
              context,
              text: number,
              isTextWidget: true,
              color: AppColors.kWhiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: MuvamTexts.bodySmall12(
            context,
            text: text,
            isTextWidget: true,
          ),
        ),
      ],
    );
  }
}
