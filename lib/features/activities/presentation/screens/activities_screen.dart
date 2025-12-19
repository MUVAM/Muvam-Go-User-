import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/activities/presentation/widgets/active_tab.dart';
import 'package:muvam/features/activities/presentation/widgets/history_tab.dart';
import 'package:muvam/features/activities/presentation/widgets/prebooking_tab.dart';
import 'package:provider/provider.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ActivitiesScreenState createState() => ActivitiesScreenState();
}

class ActivitiesScreenState extends State<ActivitiesScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivitiesTabsProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    context.read<RidesProvider>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 40.h,
            left: 20.w,
            child: Container(
              width: 45.w,
              height: 45.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100.r),
              ),
              padding: EdgeInsets.all(10.w),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back, color: Colors.black, size: 20.sp),
              ),
            ),
          ),
          Positioned(
            top: 100.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Color(0x767680).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  _buildTabItem('Prebooking', 0),
                  Container(
                    width: 0.5.w,
                    height: 28.h,
                    color: Colors.grey.shade300,
                  ),
                  _buildTabItem('Active', 1),
                  Container(
                    width: 0.5.w,
                    height: 28.h,
                    color: Colors.grey.shade300,
                  ),
                  _buildTabItem('History', 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: 197.h,
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: SingleChildScrollView(child: _getCurrentTabContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          width: 116.33.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7.r),
            border: isSelected
                ? Border.all(color: Colors.grey.shade300, width: 0.5)
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return PrebookingTab();
      case 1:
        return ActiveTab();
      case 2:
        return HistoryTab();
      default:
        return PrebookingTab();
    }
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(ConstColors.mainColor)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
