import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/globalCallService.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/chat/presentation/screens/call_screen.dart';
import 'package:muvam/features/profile/data/providers/profile_provider.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/promo/data/providers/promo_code_provider.dart';
import 'package:muvam/features/referral/data/providers/referral_provider.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/shared/presentation/screens/splash_screen.dart';
import 'package:muvam/shared/providers/connectivity_provider.dart';
import 'package:muvam/shared/providers/location_provider.dart';
import 'package:muvam/shared/providers/websocket_provider.dart';
import 'package:muvam/shared/widgets/connectivity_wrapper.dart';
import 'package:provider/provider.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   await _setupGlobalWebSocketHandler();

//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   // final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//   static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//   // @override
//   // void initState() {
//   //   super.initState();

//   //   // Initialize global call service
//   //   GlobalCallService.instance.initialize(navigatorKey);

//   //   // Setup WebSocket incoming call handler
//   //   _setupGlobalCallHandler();
//   // }
//   @override
//   void initState() {
//     super.initState();

//     // Initialize global call service with navigator key
//     GlobalCallService.instance.initialize(navigatorKey);
//   }

//   void _setupGlobalCallHandler() {
//     final webSocket = WebSocketService.instance;

//     // CRITICAL: Set up the call handler BEFORE connecting
//     webSocket.onIncomingCall = (callData) {
//       AppLogger.log('📞 Global incoming call handler triggered', tag: 'MAIN_APP');
//       AppLogger.log('📞 Call data received: $callData', tag: 'MAIN_APP');

//       // Show incoming call overlay globally
//       GlobalCallService.instance.showIncomingCall(
//         callData: callData,
//         onAccept: (sessionId) async {
//           final callerName = callData['data']?['caller_name'] ?? 'Unknown';
//           final rideId = callData['data']?['ride_id'] ?? 0;

//           AppLogger.log('✅ Call accepted - Session: $sessionId, Caller: $callerName', tag: 'MAIN_APP');

//           // Answer the call via API
//           final callService = CallService();
//           await callService.initialize();
//           await callService.answerCall(sessionId);

//           // Navigate to call screen
//           navigatorKey.currentState?.push(
//             MaterialPageRoute(
//               builder: (context) => CallScreen(
//                 driverName: callerName,
//                 rideId: rideId,
//               ),
//             ),
//           );
//         },
//         onReject: (sessionId) async {
//           AppLogger.log('❌ Call rejected - Session: $sessionId', tag: 'MAIN_APP');

//           // Reject the call via API
//           final callService = CallService();
//           await callService.initialize();
//           await callService.rejectCall(sessionId);
//         },
//       );
//     };

//     AppLogger.log('✅ Global call handler setup complete', tag: 'MAIN_APP');
//   }

//   @override
//   void dispose() {
//     GlobalCallService.instance.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(393, 852),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => AuthProvider()),
//             ChangeNotifierProvider(create: (_) => LocationProvider()),
//             ChangeNotifierProvider(create: (_) => ProfileProvider()),
//             ChangeNotifierProvider(create: (_) => WalletProvider()),
//             ChangeNotifierProvider(create: (_) => RidesProvider()),
//             ChangeNotifierProvider(create: (_) => ChatProvider()),
//             ChangeNotifierProvider(create: (_) => WebSocketProvider()),
//             ChangeNotifierProvider(create: (_) => UserProfileProvider()),
//             ChangeNotifierProvider(create: (_) => ActivitiesTabsProvider()),
//           ],
//           child: MaterialApp(
//             debugShowCheckedModeBanner: false,
//             title: 'Muvam',
//             theme: ThemeData(useMaterial3: true),
//             home: const SplashScreen(),

//             navigatorKey: MyApp.navigatorKey, // Use static key

//             // navigatorKey: navigatorKey, // IMPORTANT: Set the navigator key

//           ),
//         );
//       },
//     );
//   }
// }

//FOR PASSENGER - Fixed main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // CRITICAL: Set up WebSocket call handler BEFORE running app
  // await _setupGlobalWebSocketHandler();
  // _setupGlobalWebSocketHandlerSync();
  // GlobalCallService.instance.initialize(MyApp.navigatorKey);
  _setupGlobalWebSocketHandlerSync();

  runApp(const MyApp());
}

void _setupGlobalWebSocketHandlerSync() {
  // Get WebSocket instance WITHOUT connecting
  final webSocket = WebSocketService.instance;

  AppLogger.log(
    '🚀 ═══════════════════════════════════════',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log('🚀 DRIVER: Setting up global call handler', tag: 'MAIN_SETUP');
  AppLogger.log(
    '🚀 ═══════════════════════════════════════',
    tag: 'MAIN_SETUP',
  );

  // Check if handler already exists
  AppLogger.log(
    '📋 Handler before setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );

  // Set handler BEFORE any connection attempt
  // Set handler BEFORE any connection attempt
  webSocket.addIncomingCallListener((callData) {
    AppLogger.log(
      '📞 ═══════════════════════════════════',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log(
      '📞 DRIVER: INCOMING CALL IN MAIN.DART',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log(
      '📞 ═══════════════════════════════════',
      tag: 'DRIVER_MAIN_CALL',
    );
    AppLogger.log('📞 Raw call data: $callData', tag: 'DRIVER_MAIN_CALL');

    final callType = callData['type'];
    final messageData = callData['data'];

    AppLogger.log('📞 Call type: $callType', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Message data: $messageData', tag: 'DRIVER_MAIN_CALL');

    if (messageData == null) {
      AppLogger.log('❌ No data in call message!', tag: 'DRIVER_MAIN_CALL');
      return;
    }

    final sessionId = messageData['session_id'];
    final callerName = messageData['caller_name'] ?? 'Passenger';
    final rideId = messageData['ride_id'] ?? 0;
    final recipientId = messageData['recipient_id'];

    AppLogger.log('📞 Session ID: $sessionId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Caller Name: $callerName', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Ride ID: $rideId', tag: 'DRIVER_MAIN_CALL');
    AppLogger.log('📞 Recipient ID: $recipientId', tag: 'DRIVER_MAIN_CALL');

    // Only show for call_initiate
    if (callType == 'call_initiate') {
      AppLogger.log(
        '✅ Showing incoming call overlay...',
        tag: 'DRIVER_MAIN_CALL',
      );

      try {
        // Show incoming call overlay globally
        GlobalCallService.instance.showIncomingCall(
          callData: callData,
          onAccept: (sessionId) async {
            AppLogger.log(
              '✅ DRIVER: Call accepted - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            // Answer the call logic
            AppLogger.log(
              '✅ DRIVER: User accepted call - Session: $sessionId',
              tag: 'DRIVER_MAIN_CALL',
            );

            // 1. Navigate to Call Screen IMMEDIATELY (Optimistic UI)
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
              AppLogger.log(
                '✅ Navigated to CallScreen',
                tag: 'DRIVER_MAIN_CALL',
              );
            } catch (e) {
              AppLogger.error(
                '❌ Failed to navigate to CallScreen',
                error: e,
                tag: 'DRIVER_MAIN_CALL',
              );
              return; // If navigation fails, don't proceed
            }

            // The CallScreen will handle answering the call with its initialized CallService
          },
          onReject: (sessionId) async {
            AppLogger.log(
              '❌ DRIVER: Call rejected - Session: $sessionId',
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
                '❌ Error rejecting call: $e',
                tag: 'DRIVER_MAIN_CALL',
              );
            }
          },
        );
      } catch (e) {
        AppLogger.log(
          '❌ Error showing call overlay: $e',
          tag: 'DRIVER_MAIN_CALL',
        );
      }
    } else {
      AppLogger.log(
        'ℹ️ Call type is $callType (not call_initiate), passing to CallService',
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
    '📋 Handler after setup: ${webSocket.onIncomingCall != null}',
    tag: 'MAIN_SETUP',
  );
  AppLogger.log('✅ Global call handler setup complete', tag: 'MAIN_SETUP');
  AppLogger.log(
    '⚠️ DO NOT connect WebSocket yet - wait for HomeScreen',
    tag: 'MAIN_SETUP',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Make navigator key static so it can be accessed from main()
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Initialize global call service with navigator key
    GlobalCallService.instance.initialize(MyApp.navigatorKey);
  }

  @override
  void dispose() {
    GlobalCallService.instance.dispose();
    super.dispose();
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
              navigatorKey: MyApp.navigatorKey, // Use static key
            ),
          ),
        );
      },
    );
  }
}
