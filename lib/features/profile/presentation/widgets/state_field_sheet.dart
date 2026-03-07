import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class StateFieldSheet extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedState;
  final Function(String) onStateSelected;

  const StateFieldSheet({
    super.key,
    required this.controller,
    required this.selectedState,
    required this.onStateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: 'State',
          isTextWidget: true,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 5.h),
        GestureDetector(
          onTap: () async {
            final result = await context.push(AppRoutes.stateSelection.urlPath);
            if (result != null) {
              onStateSelected(result as String);
            }
          },
          child: Container(
            width: double.infinity,
            height: 47.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MuvamTexts.bodyMedium14(
                    context,
                    text: controller.text.isEmpty
                        ? 'Select State'
                        : controller.text,
                    isTextWidget: true,
                    color: controller.text.isEmpty
                        ? Colors.grey
                        : AppColors.kBlackColor,
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 12.w,
                    height: 12.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
