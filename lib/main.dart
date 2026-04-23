import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// ─── Views (MVC) ─────────────────────────────────────────────────────────────
import 'views/auth/splash_page.dart';
import 'views/auth/onboarding_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/auth/forgot_password_page.dart';
import 'views/customer/customer_main_page.dart';
import 'views/owner/owner_main_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/admin_login_page.dart';
import 'views/customer/customer_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk intl (DateFormat)
  await initializeDateFormatting('id', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase App Check: hanya aktif di Android (debug mode)
  // Web tidak memerlukan App Check untuk development
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  }

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B3A)),
        useMaterial3: true,
      ),
      home: kIsWeb ? const AdminLoginPage() : const SplashPage(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/customer-home': (context) => const CustomerMainPage(),
        '/owner-home': (context) => const OwnerMainPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-home': (context) => const AdminDashboardPage(),
        '/profile': (context) => const CustomerProfilePage(),
      },
    );
  }
}
