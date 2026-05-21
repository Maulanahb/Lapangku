import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// â”€â”€â”€ Views (MVC) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'views/auth/splash_page.dart';
import 'views/auth/onboarding_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/auth/forgot_password_page.dart';
import 'views/auth/otp_verification_page.dart';
import 'views/auth/reset_password_page.dart';
import 'views/customer/customer_main_page.dart';
import 'views/Mitra/mitra_main_page.dart';
import 'views/admin/admin_dashboard_page.dart';
import 'views/admin/admin_login_page.dart';
import 'views/auth/mitra_register/mitra_waiting_page.dart';

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

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Inisialisasi locale Indonesia untuk intl (DateFormat)
  await initializeDateFormatting('id', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // KONFIGURASI EMAIL OTP
  // 1. TAMBAHKAN CONFIG INI DULU
  EmailOTP.config(
    appName: 'LapangKu Mitra',
    otpType: OTPType.numeric,
  );

  // Kita buat template HTML sendiri yang sangat simpel
  EmailOTP.setTemplate(
    template: '''
      <div style="background-color: #f6f9fc; padding: 40px 20px; font-family: 'Helvetica Neue', Arial, sans-serif;">
        <div style="max-width: 450px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.05);">
          <div style="background-color: #1B6B3A; padding: 30px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 1px;">LAPANGKU</h1>
          </div>
          <div style="padding: 40px 35px;">
            <h2 style="color: #1B6B3A; margin: 0 0 15px; font-size: 20px; font-weight: 700;">LapangKu Mitra</h2>
            <p style="color: #4a5568; line-height: 1.6; margin: 0 0 25px; font-size: 16px;">Halo,</p>
            <p style="color: #4a5568; line-height: 1.6; margin: 0 0 30px; font-size: 16px;">Berikut adalah kode verifikasi Anda untuk masuk ke aplikasi:</p>
            
            <div style="background-color: #f7fafc; border: 1px dashed #cbd5e0; border-radius: 12px; padding: 25px; text-align: center; margin-bottom: 30px;">
              <span style="font-size: 36px; font-weight: 900; letter-spacing: 10px; color: #1B6B3A;">{{otp}}</span>
            </div>
            
            <p style="margin-top: 20px; color: #718096; font-size: 12px; line-height: 1.5;">Jangan bagikan kode ini kepada siapapun demi keamanan akun Anda.</p>
            <hr style="border: 0; border-top: 1px solid #edf2f7; margin: 25px 0;">
            <p style="font-size: 11px; color: #a0aec0; text-align: center;">© 2026 LapangKu Team</p>
          </div>
        </div>
      </div>
    ''',
  );

  // 2. LALU SET SMTP (Kodinganmu sudah benar di bawah ini)
  EmailOTP.setSMTP(
    host: 'smtp.gmail.com',
    emailPort: EmailPort.port465,
    secureType: SecureType.ssl,
    username: dotenv.env['SMTP_USERNAME'] ?? '',
    password: dotenv.env['SMTP_PASSWORD'] ?? '',
  );

  // [RESOLVED] Mengambil kode server: Firebase App Check dibatasi hanya untuk Android.
  // Ini lebih aman dan mencegah error kalau kamu sedang me-run versi Web untuk Admin.
  // if (!kIsWeb) {
  //   await FirebaseAppCheck.instance.activate(
  //     androidProvider: AndroidProvider.debug,
  //   );
  // }

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
        '/mitra-waiting': (context) => const MitraWaitingPage(),

        // [RESOLVED] Menggabungkan routing milik server dan routing milikmu
        '/profile': (context) => const CustomerProfilePage(),
        '/search': (context) => const CustomerSearchPage(),
        '/field-detail': (context) {
          final field =
              ModalRoute.of(context)!.settings.arguments as FieldModel;
          return CustomerFieldDetailPage(field: field);
        },
        '/booking-confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return BookingConfirmationPage(
            field: args['field'] as FieldModel,
            selectedDate: args['date'] as DateTime,
            selectedTimeSlots: args['timeSlots'] as List<String>,
          );
        },
        '/payment-upload': (context) {
          final booking =
              ModalRoute.of(context)!.settings.arguments as BookingModel;
          return PaymentUploadPage(booking: booking);
        },
        '/booking-detail': (context) {
          final bookingId =
              ModalRoute.of(context)!.settings.arguments as String;
          return BookingDetailPage(bookingId: bookingId);
        },
      },
    );
  }
}
