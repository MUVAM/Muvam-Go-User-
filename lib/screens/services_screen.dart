import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';
import 'coming_soon_screen.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),
              Text(
                'Service',
                style: ConstTextStyles.addHomeTitle,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ComingSoonScreen()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(ConstColors.fieldColor).withOpacity(0.12),
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
                            Text(
                              service['name']!,
                              style: ConstTextStyles.drawerItem,
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