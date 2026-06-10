/// Satu-satunya sumber kebenaran untuk semua konstanta bisnis di Lapangku.
/// Semua magic number dan string dengan makna bisnis ada di sini.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // --- Booking ---
  /// Batas waktu bayar setelah booking dibuat (dalam menit)
  static const int paymentDeadlineMinutes = 15;

  /// Biaya layanan platform per transaksi (dalam Rupiah)
  static const int serviceFee = 5000;

  // --- Firestore ---
  /// Batas maksimum item dalam query Firestore `whereIn`
  static const int firestoreWhereInLimit = 30;

  // --- Routes ---
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeOtpVerification = '/otp-verification';
  static const String routeResetPassword = '/reset-password';
  static const String routeCustomerHome = '/customer-home';
  static const String routeMitraHome = '/Mitra-home';
  static const String routeAdminLogin = '/admin-login';
  static const String routeAdminHome = '/admin-home';
  static const String routeMitraWaiting = '/mitra-waiting';
  static const String routeProfile = '/profile';
  static const String routeSearch = '/search';
  static const String routeFieldDetail = '/field-detail';
  static const String routeBookingConfirmation = '/booking-confirmation';
  static const String routeBookingDetail = '/booking-detail';
}
