import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/home/presentation/widgets/drawer_item.dart';
import 'package:muvam/features/profile/presentation/widgets/logout_sheet.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatefulWidget {
  final void Function(int index)? onNavigateToTab;
  const AppDrawer({super.key, this.onNavigateToTab});

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
    setState(() => _isDarkMode = prefs.getBool('dark_mode') ?? false);
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
  }

  void _navigateToWallet() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final hasAccount = await walletProvider.checkVirtualAccount();
    if (!mounted) return;
    context.pop();
    if (hasAccount) {
      context.pushNamed(AppRoutes.wallet.name);
    } else {
      context.pushNamed(AppRoutes.walletEmpty.name);
    }
  }

  Future<void> _launchPhoneDialer() async {
    const phoneNumber = '07032992768';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Could not open phone dialer',
          );
        }
      }
    } catch (e) {
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
      } else {
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Could not open WhatsApp',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    }
  }

  void _showContactBottomSheet() {
    context.pop();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MuvamTexts.titleMedium18(
                  context,
                  text: 'Contact us',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListTile(
              onTap: () async {
                context.pop();
                await _launchPhoneDialer();
              },
              leading: Image.asset(
                ConstImages.phoneCall,
                width: 22.w,
                height: 22.h,
              ),
              title: MuvamTexts.bodyMedium14(
                context,
                text: 'Via Call',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              onTap: () async {
                context.pop();
                await _launchWhatsApp();
              },
              leading: Image.asset(
                ConstImages.whatsapp,
                width: 22.w,
                height: 22.h,
              ),
              title: MuvamTexts.bodyMedium14(
                context,
                text: 'Via WhatsApp',
                isTextWidget: true,
                fontWeight: FontWeight.w500,
              ),
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
        color: AppColors.kWhiteColor,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: IconButton(
                  icon: Icon(Icons.close, size: 24.sp),
                  onPressed: () => context.pop(),
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
                        context.pop();
                        context.pushNamed(AppRoutes.profile.name);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profileProvider.userShortName.isNotEmpty
                                      ? profileProvider.userShortName
                                      : 'John Doe',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22.sp,
                                    color: AppColors.kBlackColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MuvamTexts.bodyMedium14(
                                context,
                                text: 'My account',
                                isTextWidget: true,
                                color: Colors.grey.shade500,
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
            Divider(thickness: 1, color: const Color(0xFFEEEEEE), height: 1),
            DrawerItem(
              title: 'Activities',
              iconPath: ConstImages.calendarBlack,
              onTap: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2);
                } else {
                  context.pop();
                  context.goNamed(
                    AppRoutes.home.name,
                    extra: {'initialIndex': 2},
                  );
                }
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
                  message: 'Coming soon...',
                );
              },
            ),
            DrawerItem(
              title: 'Promo code',
              iconPath: ConstImages.tag,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.promoCode.name);
              },
            ),
            DrawerItem(
              title: 'Referral',
              iconPath: ConstImages.settings,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.referral.name);
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
                context.pop();
                context.pushNamed(AppRoutes.faq.name);
              },
            ),
            DrawerItem(
              title: 'About',
              iconPath: ConstImages.book,
              onTap: () {
                context.pop();
                context.pushNamed(AppRoutes.aboutUs.name);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: const BoxDecoration(
                      color: AppColors.kMainColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      color: AppColors.kWhiteColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: MuvamTexts.bodyMedium14(
                      context,
                      text: 'Light mode',
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    activeColor: AppColors.kMainColor,
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
                    MuvamTexts.titleMedium18(
                      context,
                      text: 'Logout',
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEF5350),
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
          context.pop();
          context.goNamed(AppRoutes.onboarding.name);
        },
        onGoBack: () => context.pop(),
      ),
    );
  }
}
