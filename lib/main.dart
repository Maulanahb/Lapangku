import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/auth/presentation/pages/register_page.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/customer/presentation/pages/customer_main_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:flutter/foundation.dart';
import 'features/admin/presentation/pages/admin_login_page.dart';
import 'features/owner/presentation/pages/owner_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LapangKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6B3A),
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const AdminLoginPage() : const SplashPage(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/customer-home': (context) => const CustomerMainPage(),
        '/owner-home': (context) => const OwnerHomePage(),
        '/admin-home': (context) => const AdminDashboardPage(),
      },
    );
  }
}
