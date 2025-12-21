import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/globalCallService.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/chat/presentation/screens/call_screen.dart';
import 'package:muvam/features/profile/data/providers/profile_provider.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/shared/presentation/screens/splash_screen.dart';
import 'package:muvam/shared/providers/location_provider.dart';
import 'package:muvam/shared/providers/websocket_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  @override
  void initState() {
    super.initState();
    
    // Initialize global call service
    GlobalCallService.instance.initialize(navigatorKey);
    
    // Setup WebSocket incoming call handler
    _setupGlobalCallHandler();
  }

  void _setupGlobalCallHandler() {
    final webSocket = WebSocketService.instance;
    
    webSocket.onIncomingCall = (callData) {
      AppLogger.log('📞 Global incoming call handler triggered', tag: 'MAIN_APP');
      
      // Show incoming call overlay globally
      GlobalCallService.instance.showIncomingCall(
        callData: callData,
        onAccept: (sessionId) async {
          final callerName = callData['data']?['caller_name'] ?? 'Unknown';
          final rideId = callData['data']?['ride_id'] ?? 0;
          
          // Answer the call via API
          final callService = CallService();
          await callService.answerCall(sessionId);
          
          // Navigate to call screen
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CallScreen(
                driverName: callerName,
                rideId: rideId,
              ),
            ),
          );
        },
        onReject: (sessionId) async {
          // Reject the call via API
          final callService = CallService();
          await callService.rejectCall(sessionId);
        },
      );
    };
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
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Muvam',
            theme: ThemeData(useMaterial3: true),
            home: const SplashScreen(),
            navigatorKey: navigatorKey, // IMPORTANT: Set the navigator key

          ),
        );
      },
    );
  }
}
