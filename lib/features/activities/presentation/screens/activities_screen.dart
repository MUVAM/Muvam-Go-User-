import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/activities/presentation/widgets/active_tab.dart';
import 'package:muvam/features/activities/presentation/widgets/history_tab.dart';
import 'package:muvam/features/activities/presentation/widgets/prebooking_tab.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ActivitiesScreenState createState() => ActivitiesScreenState();
}

class ActivitiesScreenState extends State<ActivitiesScreen>
    with WidgetsBindingObserver {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivitiesTabsProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<ActivitiesTabsProvider>().stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = Provider.of<ActivitiesTabsProvider>(
      context,
      listen: false,
    );

    switch (state) {
      case AppLifecycleState.resumed:
        provider.resumePolling();
        break;
      case AppLifecycleState.paused:
        provider.pausePolling();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: Stack(
        children: [
          Positioned(
            top: 40.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: const Color(0x767680).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  _buildTabItem('Prebooking', 0),
                  _buildDivider(0),
                  _buildTabItem('Active', 1),
                  _buildDivider(1),
                  _buildTabItem('History', 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: 100.h,
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: SingleChildScrollView(child: _getCurrentTabContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(int dividerIndex) {
    final bool shouldHide =
        _selectedTabIndex == dividerIndex ||
        _selectedTabIndex == dividerIndex + 1;

    return Opacity(
      opacity: shouldHide ? 0.0 : 1.0,
      child: Container(width: 0.5.w, height: 28.h, color: Colors.grey.shade500),
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
