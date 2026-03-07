import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/config/repository/ui_service.dart';
import 'package:muvam/core/config/routes/app_router.dart';
import 'package:muvam/core/config/theme/app_theme.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/services/biometric_auth_service.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/fcm_token_service.dart';
import 'package:muvam/core/services/enhanced_notification_service.dart';
import 'package:muvam/core/services/global_call_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/auth/data/providers/%20delete_account_provider.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/profile/data/providers/profile_provider.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/promo/data/providers/promo_code_provider.dart';
import 'package:muvam/features/referral/data/providers/referral_provider.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/layouts/providers/connectivity_provider.dart';
import 'package:muvam/layouts/providers/location_provider.dart';
import 'package:muvam/layouts/providers/websocket_provider.dart';
import 'package:muvam/layouts/presentation/widgets/connectivity_wrapper.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp();
  AppLogger.log('Firebase initialized', tag: 'MAIN');

  AppLogger.log('FCM background handler registered', tag: 'MAIN');
  await FCMTokenService.initializeFCM();

  EnhancedNotificationService.initEnhancedNotifications();

  _setupGlobalWebSocketHandler();

  runApp(const MyApp());
}

void _setupGlobalWebSocketHandler() {
  final webSocket = WebSocketService.instance;

  AppLogger.log('Setting up global call handler', tag: 'MAIN_SETUP');

  AppLogger.log(
    'Handler before setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );

  webSocket.addIncomingCallListener((callData) {
    AppLogger.log('Incoming call received in main.dart', tag: 'MAIN_CALL');
    AppLogger.log('Raw call data: $callData', tag: 'MAIN_CALL');

    final callType = callData['type'];
    final messageData = callData['data'];

    AppLogger.log('Call type: $callType', tag: 'MAIN_CALL');
    AppLogger.log('Message data: $messageData', tag: 'MAIN_CALL');

    if (messageData == null) {
      AppLogger.log('No data in call message', tag: 'MAIN_CALL');
      return;
    }

    final sessionId = messageData['session_id'];
    final callerName = messageData['caller_name'] ?? 'Passenger';
    final rideId = messageData['ride_id'] ?? 0;
    final recipientId = messageData['recipient_id'];

    AppLogger.log('Session ID: $sessionId', tag: 'MAIN_CALL');
    AppLogger.log('Caller Name: $callerName', tag: 'MAIN_CALL');
    AppLogger.log('Ride ID: $rideId', tag: 'MAIN_CALL');
    AppLogger.log('Recipient ID: $recipientId', tag: 'MAIN_CALL');

    if (callType == 'call_initiate') {
      AppLogger.log('Showing incoming call overlay', tag: 'MAIN_CALL');

      try {
        GlobalCallService.instance.showIncomingCall(
          callData: callData,
          onAccept: (sessionId) async {
            AppLogger.log(
              'Call accepted - Session: $sessionId',
              tag: 'MAIN_CALL',
            );

            try {
              MyApp.navigatorKey.currentState?.pushNamed(
                AppRoutes.call.name,
                arguments: {
                  'driverName': callerName,
                  'rideId': rideId,
                  'sessionId': sessionId,
                },
              );
              AppLogger.log('Navigated to CallScreen', tag: 'MAIN_CALL');
            } catch (e) {
              AppLogger.error(
                'Failed to navigate to CallScreen',
                error: e,
                tag: 'MAIN_CALL',
              );
            }
          },
          onReject: (sessionId) async {
            AppLogger.log(
              'Call rejected - Session: $sessionId',
              tag: 'MAIN_CALL',
            );
            try {
              final callService = CallService();
              try {
                await callService.rejectCall(sessionId);
              } finally {
                callService.dispose();
              }
            } catch (e) {
              AppLogger.log('Error rejecting call: $e', tag: 'MAIN_CALL');
            }
          },
        );
      } catch (e) {
        AppLogger.log('Error showing call overlay: $e', tag: 'MAIN_CALL');
      }
    } else {
      AppLogger.log(
        'Call type is $callType, passing to CallService',
        tag: 'MAIN_CALL',
      );

      if (callType == 'call_offer' || callType == 'call_ice_candidate') {
        GlobalCallService.instance.addPendingMessage(callData);
      }
    }
  });

  AppLogger.log(
    'Handler after setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log('Global call handler setup complete', tag: 'MAIN_SETUP');
  AppLogger.log(
    'Do not connect WebSocket yet - wait for HomeScreen',
    tag: 'MAIN_SETUP',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLocked = false;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
    GlobalCallService.instance.initialize(MyApp.navigatorKey);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalCallService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.log('App lifecycle state changed: $state', tag: 'LIFECYCLE');

    final biometricService = BiometricAuthService();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      biometricService.recordBackgroundTime();
      AppLogger.log('App going to background, time recorded', tag: 'LIFECYCLE');
    } else if (state == AppLifecycleState.resumed) {
      AppLogger.log('App resumed from background', tag: 'LIFECYCLE');
      biometricService.shouldLockApp().then((shouldLock) {
        AppLogger.log('Should lock app: $shouldLock', tag: 'LIFECYCLE');
        if (shouldLock && !_isLocked) {
          _isLocked = true;
          _showBiometricLockScreen();
        }
      });
    }
  }

  void _showBiometricLockScreen() {
    AppLogger.log('Showing biometric lock screen', tag: 'LIFECYCLE');

    MyApp.navigatorKey.currentState?.pushNamed(
      AppRoutes.biometricLock.name,
      arguments: {
        'onAuthenticated': () {
          _isLocked = false;
          if (MyApp.navigatorKey.currentState?.canPop() ?? false) {
            MyApp.navigatorKey.currentState?.pop();
          }
          AppLogger.log(
            'Biometric authentication successful',
            tag: 'LIFECYCLE',
          );
        },
        'isLoginScreen': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => RidesProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => WebSocketProvider()),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => ActivitiesTabsProvider()),
            ChangeNotifierProvider(create: (_) => ReferralProvider()),
            ChangeNotifierProvider(create: (_) => PromoCodeProvider()),
            ChangeNotifierProvider(create: (_) => DeleteAccountProvider()),
            ChangeNotifierProvider(create: (_) => UIService()),
          ],
          child: ConnectivityWrapper(
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Muvam',
              theme: lightTheme,
              routerConfig: _appRouter.routerConfig,
            ),
          ),
        );
      },
    );
  }
}
