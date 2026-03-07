import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';

class StateField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onStateSelected;

  const StateField({
    super.key,
    required this.controller,
    required this.onStateSelected,
  });

  @override
  State<StateField> createState() => _StateFieldState();
}

class _StateFieldState extends State<StateField> {
  String? _selectedState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.titleSmall14(
          context,
          text: 'Select State',
          isTextWidget: true,
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () async {
            final result = await context.pushNamed(
              AppRoutes.stateSelection.name,
            );
            if (result != null) {
              setState(() {
                _selectedState = result as String;
                widget.controller.text = result;
                widget.onStateSelected(result);
              });
              AppLogger.log('User selected state: $_selectedState');
            }
          },
          child: Container(
            width: double.infinity,
            height: 47.h,
            decoration: BoxDecoration(
              color: AppColors.kLocationFieldColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.controller.text.isEmpty
                        ? 'Select State'
                        : widget.controller.text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: widget.controller.text.isEmpty
                          ? Colors.grey
                          : AppColors.kBlackColor,
                    ),
                  ),
                  SvgPicture.asset(
                    ConstImages.dropDown,
                    width: 5.w,
                    height: 5.h,
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
