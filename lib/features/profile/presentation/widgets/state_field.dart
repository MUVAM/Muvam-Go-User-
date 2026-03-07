import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class StateField extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedState;
  final Function(String) onStateSelected;

  const StateField({
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
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final result = await context.push(AppRoutes.stateSelection.urlPath);
            if (result != null) {
              onStateSelected(result as String);
            }
          },
          child: Container(
            width: double.infinity,
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                    fit: BoxFit.scaleDown,
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
