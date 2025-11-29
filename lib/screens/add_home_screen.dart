import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';

class AddHomeScreen extends StatefulWidget {
  const AddHomeScreen({super.key});

  @override
  State<AddHomeScreen> createState() => _AddHomeScreenState();
}

class _AddHomeScreenState extends State<AddHomeScreen> {
  final List<String> recentLocations = [
    'Nsukka, Ogige',
    'Holy ghost Enugu',
    'Abakpa, Enugu',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back, // Using avatar as placeholder for back icon
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                 
                ],
              ),
            ),
            SizedBox(height:15.h),
             Text(
                    '    Add home',
                    style: ConstTextStyles.addHomeTitle,
                  ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                width: 353.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.fieldColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search an address',
                    prefixIcon: Icon(Icons.search, size: 20.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Recent locations',
                style: ConstTextStyles.recentLocation.copyWith(
                  color: Color(ConstColors.recentLocationColor),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            Expanded(
              child: ListView.separated(
                itemCount: recentLocations.length,
                separatorBuilder: (context, index) => Divider(thickness: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.asset(
                      ConstImages.add,
                      width: 24.w,
                      height: 24.h,
                    ),
                    title: Text(
                      recentLocations[index],
                      style: ConstTextStyles.drawerItem,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}