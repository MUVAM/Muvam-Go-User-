import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:muvam/features/home/presentation/screens/home_screen.dart';
import 'package:muvam/features/home/presentation/widgets/drawer_item.dart';
import 'package:muvam/features/profile/presentation/widgets/logout_sheet.dart';
import 'package:muvam/features/promo/presentation/screens/promo_code_screen.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/screens/profile_screen.dart';
import 'package:muvam/features/referral/presentation/screens/referral_screen.dart';
import 'package:muvam/features/support/presentation/about_screen.dart';
import 'package:muvam/features/support/presentation/faq_screen.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/features/wallet/presentation/screens/wallet_empty_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muvam/core/utils/app_logger.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  void _navigateToWallet() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final hasAccount = await walletProvider.checkVirtualAccount();

    if (!mounted) return;

    Navigator.pop(context);

    if (hasAccount) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WalletScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WalletEmptyScreen()),
      );
    }
  }

  Future<void> _launchPhoneDialer() async {
    const phoneNumber = '07032992768';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        AppLogger.log(
          'Launched phone dialer for: $phoneNumber',
          tag: 'CONTACT',
        );
      } else {
        AppLogger.error('Could not launch phone dialer', tag: 'CONTACT');
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Could not open phone dialer',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error launching phone dialer', error: e, tag: 'CONTACT');
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '2347032992768';
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        AppLogger.log('Launched WhatsApp for: $phoneNumber', tag: 'CONTACT');
      } else {
        AppLogger.error('Could not launch WhatsApp', tag: 'CONTACT');
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Could not open WhatsApp',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error launching WhatsApp', error: e, tag: 'CONTACT');
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    }
  }

  void _showContactBottomSheet() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Contact us', style: ConstTextStyles.addHomeTitle),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListTile(
              onTap: () async {
                Navigator.pop(context);
                await _launchPhoneDialer();
              },
              leading: Image.asset(
                ConstImages.phoneCall,
                width: 22.w,
                height: 22.h,
              ),
              title: Text('Via Call', style: ConstTextStyles.contactOption),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              onTap: () async {
                Navigator.pop(context);
                await _launchWhatsApp();
              },
              leading: Image.asset(
                ConstImages.whatsapp,
                width: 22.w,
                height: 22.h,
              ),
              title: Text('Via WhatsApp', style: ConstTextStyles.contactOption),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);

    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 20.h, right: 0.w),
                child: IconButton(
                  icon: Icon(Icons.close, size: 24.sp),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: [
                  profileProvider.userProfilePhoto.isNotEmpty
                      ? CircleAvatar(
                          radius: 30.r,
                          backgroundImage: NetworkImage(
                            profileProvider.userProfilePhoto,
                          ),
                        )
                      : Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileProvider.userShortName.isNotEmpty
                                ? profileProvider.userShortName
                                : 'John Doe',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My account',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16.sp,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Divider(thickness: 1, color: Color(0xFFEEEEEE), height: 1),
            DrawerItem(
              title: 'Activities',
              iconPath: ConstImages.calendarBlack,
              onTap: () {
                CustomFlushbar.showInfo(
                  context: context,
                  message: "Coming soon...",
                );
              },
            ),
            DrawerItem(
              title: 'Wallet',
              iconPath: ConstImages.walletStreamline,
              onTap: _navigateToWallet,
            ),
            DrawerItem(
              title: 'Drive with us',
              iconPath: ConstImages.carIconSvg,
              onTap: () {
                CustomFlushbar.showInfo(
                  context: context,
                  message: "Coming soon...",
                );
              },
            ),
            DrawerItem(
              title: 'Promo code',
              iconPath: ConstImages.tag,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PromoCodeScreen()),
                );
              },
            ),
            DrawerItem(
              title: 'Referral',
              iconPath: ConstImages.settings,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReferralScreen()),
                );
              },
            ),
            DrawerItem(
              title: 'Contact us',
              iconPath: ConstImages.callIcon,
              onTap: _showContactBottomSheet,
            ),
            DrawerItem(
              title: 'FAQ',
              iconPath: ConstImages.questionCircle,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FaqScreen()),
                );
              },
            ),
            DrawerItem(
              title: 'About',
              iconPath: ConstImages.book,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsScreen()),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Light mode',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    activeColor: Color(ConstColors.mainColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => _showLogoutSheet(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      ConstImages.logout,
                      width: 24.w,
                      height: 24.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeleteAccountScreen(),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      ConstImages.bin,
                      width: 24.w,
                      height: 24.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Delete account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => LogoutSheet(
        onLogout: () async {
          final profileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          await profileProvider.clearProfile();
          await authProvider.logout();

          // Close the logout sheet
          Navigator.pop(context);

          // Navigate to onboarding screen and clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        },
        onGoBack: () => Navigator.pop(context),
      ),
    );
  }
}
