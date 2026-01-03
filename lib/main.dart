import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/services/biometric_auth_service.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/fcm_token_service.dart';
import 'package:muvam/core/services/enhanced_notification_service.dart';
import 'package:muvam/core/services/global_call_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/chat/presentation/screens/call_screen.dart';
import 'package:muvam/features/profile/data/providers/profile_provider.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/profile/presentation/screens/biometric_lock_screen.dart';
import 'package:muvam/features/promo/data/providers/promo_code_provider.dart';
import 'package:muvam/features/referral/data/providers/referral_provider.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/shared/presentation/screens/splash_screen.dart';
import 'package:muvam/shared/providers/connectivity_provider.dart';
import 'package:muvam/shared/providers/location_provider.dart';
import 'package:muvam/shared/providers/websocket_provider.dart';
import 'package:muvam/shared/presentation/widgets/connectivity_wrapper.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();
  AppLogger.log('Firebase initialized', tag: 'MAIN');

  AppLogger.log('FCM background handler registered', tag: 'MAIN');
  await FCMTokenService.initializeFCM();

  EnhancedNotificationService.initEnhancedNotifications();
  // CRITICAL: Set up WebSocket call handler BEFORE running app
  _setupGlobalWebSocketHandlerSync();

  runApp(const MyApp());
}

void _setupGlobalWebSocketHandlerSync() {
  final webSocket = WebSocketService.instance;

  AppLogger.log('DRIVER: Setting up global call handler', tag: 'MAIN_SETUP');
  AppLogger.log('═══════════════════════════════════════', tag: 'MAIN_SETUP');

  // Check if handler already exists
  AppLogger.log(
    'Handler before setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );

  // Set handler BEFORE any connection attempt
  webSocket.addIncomingCallListener((callData) {
    AppLogger.log(
      '══════════════════════════════════',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log(
      'DRIVER: INCOMING CALL IN MAIN.DART',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log(
      '══════════════════════════════════',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log('Raw call data: $callData', tag: 'DRIVER_MAIN_CALL');

    final callType = callData['type'];
    final messageData = callData['data'];

    AppLogger.log('Call type: $callType', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Message data: $messageData', tag: 'DRIVER_MAIN_CALL');

    if (messageData == null) {
      AppLogger.log('No data in call message!', tag: 'DRIVER_MAIN_CALL');
      return;
    }

    final sessionId = messageData['session_id'];
    final callerName = messageData['caller_name'] ?? 'Passenger';
    final rideId = messageData['ride_id'] ?? 0;
    final recipientId = messageData['recipient_id'];

    AppLogger.log('Session ID: $sessionId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Caller Name: $callerName', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Ride ID: $rideId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('Recipient ID: $recipientId', tag: 'DRIVER_MAIN_CALL');

    // Only show for call_initiate
    if (callType == 'call_initiate') {
      AppLogger.log(
        'Showing incoming call overlay...',
        tag: 'DRIVER_MAIN_CALL',
      );

      try {
        // Show incoming call overlay globally
        GlobalCallService.instance.showIncomingCall(
          callData: callData,
          onAccept: (sessionId) async {
            AppLogger.log(
              'DRIVER: Call accepted - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            // Answer the call logic
            AppLogger.log(
              'DRIVER: User accepted call - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            try {
              MyApp.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    driverName: callerName,
                    rideId: rideId,
                    sessionId: sessionId,
                  ),
                ),
              );
              AppLogger.log('Navigated to CallScreen', tag: 'DRIVER_MAIN_CALL');
            } catch (e) {
              AppLogger.error(
                'Failed to navigate to CallScreen',
                error: e,
                tag: 'DRIVER_MAIN_CALL',
              );
              return;
            }
          },
          onReject: (sessionId) async {
            AppLogger.log(
              'DRIVER: Call rejected - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            try {
              // Reject the call via API
              final callService = CallService();
              // Do NOT call initialize() here
              try {
                await callService.rejectCall(sessionId);
              } finally {
                callService.dispose();
              }
            } catch (e) {
              AppLogger.log(
                'Error rejecting call: $e',
                tag: 'DRIVER_MAIN_CALL',
              );
            }
          },
        );
      } catch (e) {
        AppLogger.log(
          'Error showing call overlay: $e',
          tag: 'DRIVER_MAIN_CALL',
        );
      }
    } else {
      AppLogger.log(
        'Call type is $callType (not call_initiate), passing to CallService',
        tag: 'DRIVER_MAIN_CALL',
      );

      // Buffer WebRTC messages that might arrive before CallScreen is ready
      if (callType == 'call_offer' || callType == 'call_ice_candidate') {
        GlobalCallService.instance.addPendingMessage(callData);
      }
    }
  });

  // Verify handler was set
  AppLogger.log(
    'Handler after setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log('Global call handler setup complete', tag: 'MAIN_SETUP');
  AppLogger.log(
    'DO NOT connect WebSocket yet - wait for HomeScreen',
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

  @override
  void initState() {
    super.initState();

    // Initialize global call service with navigator key
    GlobalCallService.instance.initialize(MyApp.navigatorKey);

    // Add lifecycle observer
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
      // App is going to background
      biometricService.recordBackgroundTime();
      AppLogger.log('App going to background, time recorded', tag: 'LIFECYCLE');
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground
      AppLogger.log('App resumed from background', tag: 'LIFECYCLE');

      // Check if we should lock the app
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

    // Use the navigator key to show the lock screen
    MyApp.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => BiometricLockScreen(
          onAuthenticated: () {
            _isLocked = false;
            Navigator.of(context).pop();
            AppLogger.log(
              'Biometric authentication successful',
              tag: 'LIFECYCLE',
            );
          },
          isLoginScreen: false,
        ),
        fullscreenDialog: true,
      ),
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
            ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
            ChangeNotifierProvider(create: (_) => PromoCodeProvider()),
          ],
          child: ConnectivityWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Muvam',
              theme: ThemeData(useMaterial3: true),
              home: const SplashScreen(),
              navigatorKey: MyApp.navigatorKey,
            ),
          ),
        );
      },
    );
  }
}
