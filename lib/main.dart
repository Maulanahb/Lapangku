import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lapangku/services/firebase/push_notification_service.dart';

// --- Views ---
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

// --- Customer Views ---
import 'views/customer/customer_profile_page.dart';
import 'views/customer/customer_search_page.dart';
import 'views/customer/customer_field_detail_page.dart';
import 'views/customer/booking_confirmation_page.dart';
import 'views/customer/booking_detail_page.dart';
import 'models/field/field_model.dart';

void main() async {
  // Inisialisasi bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) {
      debugPrint("Warning: .env file not found or failed to load. Error: $e");
    }
  }

  try {
    // Inisialisasi locale
    await initializeDateFormatting('id', null);

    // Inisialisasi Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Setup Push Notification
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.instance.initialize();

    // Konfigurasi Email OTP
    EmailOTP.config(
      appName: 'LapangKu Mitra',
      otpType: OTPType.numeric,
      appEmail: dotenv.env['SMTP_USERNAME'] ?? 'lapangku1@gmail.com',
    );

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

    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: dotenv.env['SMTP_USERNAME'] ?? 'lapangku1@gmail.com',
      password: dotenv.env['SMTP_PASSWORD'] ?? 'grhnkjzimuukanyn',
    );

    // Run App
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('CRITICAL STARTUP ERROR: $error');
      debugPrint(stackTrace.toString());
    }
    
    // Tampilkan error di layar
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal Memulai Aplikasi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Handle deep links in foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('⚠️ [DeepLink] Error listening to links: $err');
    });

    // Handle deep links on cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 [DeepLink] Received deep link: $uri');
    final navigator = PushNotificationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ [DeepLink] Navigator is not ready yet');
      return;
    }

    // Handle lapangku schemes
    if (uri.scheme == 'lapangku') {
      final path = uri.host;
      final id = uri.queryParameters['id'];

      if (id != null && id.isNotEmpty) {
        if (path == 'field-detail') {
          navigator.pushNamed('/field-detail', arguments: id);
        } else if (path == 'booking-detail') {
          navigator.pushNamed('/booking-detail', arguments: id);
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LapangKu',
      debugShowCheckedModeBanner: false,
      // Navigator key untuk navigasi dari push notification
      navigatorKey: PushNotificationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B3A)),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
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
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is FieldModel) {
            return CustomerFieldDetailPage(field: args);
          } else if (args is String) {
            return CustomerFieldDetailPage(fieldId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text('Invalid arguments')),
            );
          }
        },
        '/booking-confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments!
              as Map<String, dynamic>;
          return BookingConfirmationPage(
            field: args['field'] as FieldModel,
            selectedDate: args['date'] as DateTime,
            selectedTimeSlots: args['timeSlots'] as List<String>,
          );
        },
        '/booking-detail': (context) {
          final bookingId =
              ModalRoute.of(context)!.settings.arguments! as String;
          return BookingDetailPage(bookingId: bookingId);
        },
      },
    );
  }
}
