import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam/features/home/presentation/screens/home_screen.dart';
import 'package:muvam/features/home/presentation/widgets/app_drawer.dart';
import 'package:muvam/features/services/presentation/screens/services_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  DateTime? _lastBackPress;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const ServicesScreen(),
    ActivitiesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > Duration(seconds: 2)) {
            _lastBackPress = now;
            CustomFlushbar.showInfo(
              context: context,
              message: 'Press back again to exit',
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: Color(ConstColors.mainColor),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                ConstImages.homeIcon,
                width: 24.w,
                height: 24.h,
                color: _currentIndex == 0
                    ? Color(ConstColors.mainColor)
                    : Colors.grey,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                ConstImages.services,
                width: 24.w,
                height: 24.h,
                color: _currentIndex == 1
                    ? Color(ConstColors.mainColor)
                    : Colors.grey,
              ),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                ConstImages.activities,
                width: 24.w,
                height: 24.h,
                color: _currentIndex == 2
                    ? Color(ConstColors.mainColor)
                    : Colors.grey,
              ),
              label: 'Activities',
            ),
          ],
        ),
      ),
    );
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
}
