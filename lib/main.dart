import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/profile/data/providers/profile_provider.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Muvam',
            theme: ThemeData(useMaterial3: true),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
