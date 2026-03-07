import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> services = [
      {'name': 'Shop', 'image': ConstImages.serviceShop},
      {'name': 'Food', 'image': ConstImages.food},
      {'name': 'Rent bike', 'image': ConstImages.bike},
      {'name': 'Escorts', 'image': ConstImages.serviceEscort},
    ];

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              MuvamTexts.titleMedium18(
                context,
                text: 'Service',
                isTextWidget: true,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 30.h),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return GestureDetector(
                      onTap: () {
                        context.pushNamed(AppRoutes.comingSoon.name);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.kFieldColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              service['image']!,
                              width: 60.w,
                              height: 60.h,
                            ),
                            SizedBox(height: 10.h),
                            MuvamTexts.bodyMedium14(
                              context,
                              text: service['name']!,
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
