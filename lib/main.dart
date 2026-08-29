// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/user_dashboard.dart';
import 'services/auth_service.dart';

// ✅ NEW: Import subscription provider
import 'providers/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ EXISTING: Unchanged
        ChangeNotifierProvider(create: (_) => UserAuthService()),
        
        // ✅ NEW: Add SubscriptionProvider (doesn't affect existing)
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Expenso',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const UserDashboard(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}