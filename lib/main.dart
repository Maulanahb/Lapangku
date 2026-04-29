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
import 'views/auth/otp_verification_page.dart';
import 'views/auth/reset_password_page.dart';
import 'views/customer/customer_main_page.dart';
import 'views/Mitra/Mitra_main_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/admin_login_page.dart';

// [RESOLVED] Menggabungkan import milik server (profile) dan milikmu (search, detail, model)
import 'views/customer/customer_profile_page.dart';
import 'views/customer/customer_search_page.dart';
import 'views/customer/customer_field_detail_page.dart';
import 'views/customer/booking_confirmation_page.dart';
import 'views/customer/payment_upload_page.dart';
import 'views/customer/booking_detail_page.dart';
import 'models/field/field_model.dart';
import 'models/booking/booking_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia untuk intl (DateFormat)
  await initializeDateFormatting('id', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // [RESOLVED] Mengambil kode server: Firebase App Check dibatasi hanya untuk Android.
  // Ini lebih aman dan mencegah error kalau kamu sedang me-run versi Web untuk Admin.
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
      // Setelan home sudah otomatis mendeteksi Web (untuk admin) atau Mobile (Splash untuk customer)
      home: kIsWeb ? const AdminLoginPage() : const SplashPage(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/otp-verification': (context) => const OtpVerificationPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/customer-home': (context) => const CustomerMainPage(),
        '/Mitra-home': (context) => const MitraMainPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-home': (context) => const AdminDashboardPage(),
        
        // [RESOLVED] Menggabungkan routing milik server dan routing milikmu
        '/profile': (context) => const CustomerProfilePage(),
        '/search': (context) => const CustomerSearchPage(),
        '/field-detail': (context) {
          final field = ModalRoute.of(context)!.settings.arguments as FieldModel;
          return CustomerFieldDetailPage(field: field);
        },
        '/booking-confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BookingConfirmationPage(
            field: args['field'] as FieldModel,
            selectedDate: args['date'] as DateTime,
            selectedTimeSlots: args['timeSlots'] as List<String>,
          );
        },
        '/payment-upload': (context) {
          final booking = ModalRoute.of(context)!.settings.arguments as BookingModel;
          return PaymentUploadPage(booking: booking);
        },
        '/booking-detail': (context) {
          final bookingId = ModalRoute.of(context)!.settings.arguments as String;
          return BookingDetailPage(bookingId: bookingId);
        },
      },
    );
  }
}
