import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/extension.dart';

class VehicleSheet extends StatelessWidget {
  final List<String> vehicleTypes;
  final int selectedVehicleIndex;
  final Function(int) onVehicleSelected;

  const VehicleSheet({
    super.key,
    required this.vehicleTypes,
    required this.selectedVehicleIndex,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 69.w,
            height: 5.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          MuvamTexts.titleMedium18(
            context,
            text: 'Select Vehicle',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 20.h),
          ...vehicleTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = selectedVehicleIndex == index;
            return GestureDetector(
              onTap: () {
                onVehicleSelected(index);
                context.pop();
              },
              child: Container(
                width: double.infinity,
                height: 60.h,
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.kMainColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.kMainColor
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/car.png',
                      width: 55.w,
                      height: 26.h,
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: MuvamTexts.bodyLarge16(
                        context,
                        text: type,
                        isTextWidget: true,
                        color: isSelected
                            ? AppColors.kWhiteColor
                            : AppColors.kBlackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.kWhiteColor,
                        size: 20.sp,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
