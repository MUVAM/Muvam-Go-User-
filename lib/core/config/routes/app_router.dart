import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/models/ride_data.dart';
import 'package:muvam/features/auth/presentation/screens/create_account_screen.dart';
import 'package:muvam/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:muvam/features/auth/presentation/screens/lga_selection_screen.dart';
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:muvam/features/auth/presentation/screens/otp_screen.dart';
import 'package:muvam/features/auth/presentation/screens/state_selection_screen.dart';
import 'package:muvam/features/chat/presentation/screens/call_screen.dart';
import 'package:muvam/features/chat/presentation/screens/chat_screen.dart';
import 'package:muvam/features/home/presentation/screens/add_favourite_screen.dart';
import 'package:muvam/features/home/presentation/screens/add_home_screen.dart';
import 'package:muvam/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:muvam/features/home/presentation/screens/map_picker_screen.dart';
import 'package:muvam/features/home/presentation/screens/map_selection_screen.dart';
import 'package:muvam/features/profile/presentation/screens/app_lock_settings_screen.dart';
import 'package:muvam/features/profile/presentation/screens/biometric_lock_screen.dart';
import 'package:muvam/features/profile/presentation/screens/edit_full_name_screen.dart';
import 'package:muvam/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:muvam/features/profile/presentation/screens/profile_screen.dart';
import 'package:muvam/features/promo/presentation/promo_code_screen.dart';
import 'package:muvam/features/referral/presentation/screens/referral_rules_screen.dart';
import 'package:muvam/features/referral/presentation/screens/referral_screen.dart';
import 'package:muvam/features/services/presentation/services_screen.dart';
import 'package:muvam/features/support/presentation/about_screen.dart';
import 'package:muvam/features/support/presentation/faq_screen.dart';
import 'package:muvam/features/trips/presentation/screens/active_trip_screen.dart';
import 'package:muvam/features/trips/presentation/screens/custom_tip_screen.dart';
import 'package:muvam/features/trips/presentation/screens/edit_prebooking_screen.dart';
import 'package:muvam/features/trips/presentation/screens/history_cancelled_screen.dart';
import 'package:muvam/features/trips/presentation/screens/history_completed_screen.dart';
import 'package:muvam/features/trips/presentation/screens/trip_details_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/account_created_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/buy_gift_card_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/get_account_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/how_to_fund_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/wallet_empty_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:muvam/layouts/presentation/screens/coming_soon_screen.dart';
import 'package:muvam/layouts/presentation/screens/payment_webview_screen.dart';
import 'package:muvam/layouts/presentation/screens/splash_screen.dart';
import 'package:muvam/layouts/presentation/screens/tip_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigationKey =
      GlobalKey<NavigatorState>();

  static String? _lastKnownRoute;

  BuildContext? get mainBuildContext => navigationKey.currentState?.context;

  static AppRoutes get _getInitialPath {
    if (_lastKnownRoute != null && _lastKnownRoute!.isNotEmpty) {
      for (final route in AppRoutes.values) {
        if (route.urlPath == _lastKnownRoute!) {
          return route;
        }
      }
    }
    return AppRoutes.splash;
  }

  late final GoRouter routerConfig = _buildRouter();

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: navigationKey,
      initialLocation: _getInitialPath.urlPath,
      debugLogDiagnostics: true,
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
      redirect: (context, state) {
        final String? path = state.fullPath;
        if (path != null && path.isNotEmpty && path != '/') {
          _lastKnownRoute = path;
        }
        AppLogger.log('Navigating to: $path', tag: 'ROUTER');
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash.urlPath,
          name: AppRoutes.splash.name,
          pageBuilder: (context, state) =>
              _buildPlatformPage(const SplashScreen()),
        ),
        GoRoute(
          path: AppRoutes.onboarding.urlPath,
          name: AppRoutes.onboarding.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const OnboardingScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.otp.urlPath,
          name: AppRoutes.otp.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              OtpScreen(phoneNumber: extra['phoneNumber'] as String),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.createAccount.urlPath,
          name: AppRoutes.createAccount.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const CreateAccountScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.deleteAccount.urlPath,
          name: AppRoutes.deleteAccount.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const DeleteAccountScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.stateSelection.urlPath,
          name: AppRoutes.stateSelection.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const StateSelectionScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.lgaSelection.urlPath,
          name: AppRoutes.lgaSelection.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              LgaSelectionScreen(
                selectedState: extra['selectedState'] as String,
              ),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.home.urlPath,
          name: AppRoutes.home.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialIndex = extra?['initialIndex'] as int? ?? 0;
            return _buildPlatformPage(
              MainNavigationScreen(initialIndex: initialIndex),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.activeTrip.urlPath,
          name: AppRoutes.activeTrip.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              ActiveTripScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.historyCompleted.urlPath,
          name: AppRoutes.historyCompleted.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              HistoryCompletedScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.historyCancelled.urlPath,
          name: AppRoutes.historyCancelled.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              HistoryCancelledScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.tripDetails.urlPath,
          name: AppRoutes.tripDetails.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              TripDetailsScreen(rideId: extra['rideId'] as int),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.editPrebooking.urlPath,
          name: AppRoutes.editPrebooking.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              EditPrebookingScreen(
                ride: extra['ride'] as RideData,
                initialScheduledAt: extra['initialScheduledAt'] as String?,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.tip.urlPath,
          name: AppRoutes.tip.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildSlidePage(
              TipScreen(rideId: extra?['rideId'] as int?),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.customTip.urlPath,
          name: AppRoutes.customTip.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const CustomTipScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.chat.urlPath,
          name: AppRoutes.chat.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              ChatScreen(
                rideId: extra['rideId'] as int,
                driverName: extra['driverName'] as String,
                driverId: extra['driverId'] as String,
                driverImage: extra['driverImage'] as String?,
                driverPhone: extra['driverPhone'] as String?,
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.call.urlPath,
          name: AppRoutes.call.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              CallScreen(
                driverName: extra['driverName'] as String,
                rideId: extra['rideId'] as int,
                sessionId: extra['sessionId'] as int?,
              ),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.profile.urlPath,
          name: AppRoutes.profile.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ProfileScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.editProfile.urlPath,
          name: AppRoutes.editProfile.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const EditProfileScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.editFullName.urlPath,
          name: AppRoutes.editFullName.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const EditFullNameScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.biometricLock.urlPath,
          name: AppRoutes.biometricLock.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildPlatformPage(
              BiometricLockScreen(
                onAuthenticated:
                    extra?['onAuthenticated'] as VoidCallback? ?? () {},
                isLoginScreen: extra?['isLoginScreen'] as bool? ?? false,
              ),
              fullscreenDialog: true,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.appLockSettings.urlPath,
          name: AppRoutes.appLockSettings.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AppLockSettingsScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.addFavourite.urlPath,
          name: AppRoutes.addFavourite.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AddFavouriteScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.addHome.urlPath,
          name: AppRoutes.addHome.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildSlidePage(
              AddHomeScreen(
                locationType: extra?['locationType'] as String? ?? 'home',
              ),
              direction: _SlideDirection.fromRight,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.mapPicker.urlPath,
          name: AppRoutes.mapPicker.name,
          pageBuilder: (context, state) =>
              _buildPlatformPage(const MapPickerScreen()),
        ),
        GoRoute(
          path: AppRoutes.paymentWebView.urlPath,
          name: AppRoutes.paymentWebView.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _buildSlidePage(
              PaymentWebViewScreen(
                authorizationUrl: extra['authorizationUrl'] as String,
                reference: extra['reference'] as String,
                onPaymentSuccess: extra['onPaymentSuccess'] as VoidCallback,
              ),
              direction: _SlideDirection.fromBottom,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.mapSelection.urlPath,
          name: AppRoutes.mapSelection.name,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return _buildPlatformPage(
              MapSelectionScreen(
                isFromField: extra?['isFromField'] as bool? ?? true,
                initialLocation: extra?['initialLocation'] as LatLng?,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.services.urlPath,
          name: AppRoutes.services.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ServicesScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.comingSoon.urlPath,
          name: AppRoutes.comingSoon.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ComingSoonScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.wallet.urlPath,
          name: AppRoutes.wallet.name,
          pageBuilder: (context, state) =>
              _buildPlatformPage(const WalletScreen()),
        ),
        GoRoute(
          path: AppRoutes.walletEmpty.urlPath,
          name: AppRoutes.walletEmpty.name,
          pageBuilder: (context, state) =>
              _buildPlatformPage(const WalletEmptyScreen()),
        ),
        GoRoute(
          path: AppRoutes.accountCreated.urlPath,
          name: AppRoutes.accountCreated.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AccountCreatedScreen(),
            direction: _SlideDirection.fromBottom,
          ),
        ),
        GoRoute(
          path: AppRoutes.getAccount.urlPath,
          name: AppRoutes.getAccount.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const GetAccountScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.howToFund.urlPath,
          name: AppRoutes.howToFund.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const HowToFundScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.buyGiftCard.urlPath,
          name: AppRoutes.buyGiftCard.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const BuyGiftCardScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.referral.urlPath,
          name: AppRoutes.referral.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ReferralScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.referralRules.urlPath,
          name: AppRoutes.referralRules.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const ReferralRulesScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.promoCode.urlPath,
          name: AppRoutes.promoCode.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const PromoCodeScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.aboutUs.urlPath,
          name: AppRoutes.aboutUs.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const AboutUsScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
        GoRoute(
          path: AppRoutes.faq.urlPath,
          name: AppRoutes.faq.name,
          pageBuilder: (context, state) => _buildSlidePage(
            const FaqScreen(),
            direction: _SlideDirection.fromRight,
          ),
        ),
      ],
    );
  }

  void clearStoredRoute() {
    _lastKnownRoute = null;
  }

  static Page _buildPlatformPage(
    Widget page, {
    LocalKey? key,
    String? name,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (Platform.isIOS) {
      return CupertinoPage(
        key: key,
        name: name,
        child: page,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }
    return MaterialPage(
      key: key,
      name: name,
      child: page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  static Page _buildSlidePage(
    Widget page, {
    LocalKey? key,
    String? name,
    bool maintainState = true,
    bool fullscreenDialog = false,
    _SlideDirection direction = _SlideDirection.fromRight,
  }) {
    return CustomTransitionPage(
      key: key,
      name: name,
      child: page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = switch (direction) {
          _SlideDirection.fromRight => const Offset(1.0, 0.0),
          _SlideDirection.fromLeft => const Offset(-1.0, 0.0),
          _SlideDirection.fromBottom => const Offset(0.0, 1.0),
          _SlideDirection.fromTop => const Offset(0.0, -1.0),
        };
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

enum _SlideDirection { fromRight, fromLeft, fromBottom, fromTop }
