import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level background message handler — HARUS di top-level (bukan method dari class).
/// Dipanggil saat notifikasi diterima ketika app di background/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM Background] ${message.notification?.title}');
}

/// Service singleton yang menangani seluruh lifecycle Firebase Cloud Messaging.
///
/// Tanggung jawab:
/// - Meminta izin notifikasi ke OS
/// - Mendapatkan & menyimpan FCM device token ke Firestore
/// - Menampilkan notifikasi saat app di foreground (via flutter_local_notifications)
/// - Menangani tap notifikasi untuk navigasi ke halaman spesifik
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  /// Global navigator key — diset dari MaterialApp untuk navigasi dari notif
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Entry point utama. Panggil setelah Firebase.initializeApp() di main.dart.
  Future<void> initialize() async {
    // Skip di Web — FCM Web butuh setup VAPID key terpisah
    if (kIsWeb) return;

    await _requestPermission();
    await _initLocalNotifications();
    _setupForegroundHandler();
    _setupNotificationTapHandler();
    _onTokenRefresh();

    // Dapatkan dan simpan token awal
    await _getFCMTokenAndSave();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Meminta izin notifikasi ke OS (Android 13+ / iOS).
  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 [FCM] Notification permission: ${settings.authorizationStatus}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FCM TOKEN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mendapatkan FCM token dan langsung simpan ke Firestore.
  Future<void> _getFCMTokenAndSave() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('🔔 [FCM] Token: ${token.substring(0, 20)}...');
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Gagal mendapatkan token: $e');
    }
  }

  /// Simpan FCM token ke Firestore berdasarkan role user.
  /// - Customer/Admin → koleksi `users/{uid}`
  /// - Mitra → koleksi `mitra/{uid}`
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Simpan ke Firestore lapangku-db
      final String uid = user.uid;
      await FirestoreService.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('DEBUG FCM: Token berhasil disimpan ke lapangku-db');

      debugPrint('✅ [FCM] Token tersimpan: ${user.uid}');
    } catch (e) {
      debugPrint('⚠️ [FCM] Gagal menyimpan token: $e');
    }
  }

  /// Listener jika FCM token berubah (di-rotate oleh Firebase).
  void _onTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 [FCM] Token refreshed');
      _saveTokenToFirestore(newToken);
    });
  }

  /// Hapus FCM token dari Firestore saat logout.
  /// Dipanggil dari AuthService.logout().
  Future<void> removeToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final String uid = user.uid;
      await FirestoreService.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      print('DEBUG FCM: Token berhasil dihapus dari lapangku-db');
    } catch (e) {
      debugPrint('⚠️ [FCM] Gagal menghapus token: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL NOTIFICATIONS (Foreground)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inisialisasi flutter_local_notifications untuk menampilkan notif di foreground.
  Future<void> _initLocalNotifications() async {
    // Android channel dengan prioritas tinggi agar muncul sebagai heads-up
    const androidChannel = AndroidNotificationChannel(
      'lapangku_channel',
      'LapangKu Notifications',
      description: 'Notifikasi booking, pembayaran, dan pengingat dari LapangKu',
      importance: Importance.high,
      playSound: true,
    );

    // Buat channel di Android
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Inisialisasi plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotif.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
  }

  /// Handler saat user mengetuk local notification (foreground notification).
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromNotification(data);
    } catch (e) {
      debugPrint('⚠️ [FCM] Gagal parse notification payload: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Menangani notifikasi yang diterima saat app di foreground.
  /// Menampilkan sebagai local notification agar ada banner/heads-up.
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM Foreground] ${message.notification?.title}');

      final notification = message.notification;
      final android = message.notification?.android;

      // Tampilkan sebagai local notification (Android)
      if (notification != null && !kIsWeb) {
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'lapangku_channel',
              'LapangKu Notifications',
              channelDescription: 'Notifikasi booking, pembayaran, dan pengingat dari LapangKu',
              importance: Importance.high,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          // Kirim data sebagai payload agar bisa navigasi saat di-tap
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  /// Menangani tap pada notifikasi saat app di background/terminated.
  void _setupNotificationTapHandler() {
    // App sedang di background → user tap notifikasi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM Tap-Background] ${message.notification?.title}');
      _navigateFromNotification(message.data);
    });

    // App terminated → user tap notifikasi → app dibuka
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 [FCM Tap-Terminated] ${message.notification?.title}');
        // Delay sedikit agar navigator sudah ready
        Future.delayed(const Duration(seconds: 1), () {
          _navigateFromNotification(message.data);
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Navigasi ke halaman spesifik berdasarkan data payload notifikasi.
  void _navigateFromNotification(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] ?? '';
    final targetId = data['targetId'] ?? '';

    switch (type) {
      case 'booking':
        if (targetId.isNotEmpty) {
          navigator.pushNamed('/booking-detail', arguments: targetId);
        }
        break;
      // Untuk tipe lain (payout, review, system), tetap di halaman saat ini
      // karena navigasi ke halaman tersebut memerlukan context khusus Mitra/Admin
      default:
        debugPrint('🔔 [FCM] Notification type "$type" — no specific navigation');
        break;
    }
  }
}
