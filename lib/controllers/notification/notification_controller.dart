import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/notification/notification_model.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/core/services/firestore_service.dart';

// Memantau daftar notifikasi untuk Customer secara real-time
final notificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirestoreService.instance
      .collection('notifikasi')
      .where('customer_id', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList());
});

// Menghitung jumlah notifikasi yang belum dibaca (misal untuk icon badge merah)
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

// Memantau daftar notifikasi khusus untuk Mitra secara real-time
final mitraNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirestoreService.instance
      .collection('notifikasi')
      .where('mitraId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList());
});

// Controller untuk mengelola interaksi dengan notifikasi (baca, hapus)
class NotificationController {
  final _db = FirestoreService.instance;

  // Menandai satu notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifikasi').doc(notificationId).update({'isRead': true});
  }

  // Menandai SEMUA notifikasi Customer sebagai sudah dibaca sekaligus
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notifikasi')
        .where('customer_id', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Menandai SEMUA notifikasi Mitra sebagai sudah dibaca sekaligus
  Future<void> markAllMitraAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notifikasi')
        .where('mitraId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Menghapus satu notifikasi dari database
  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifikasi').doc(notificationId).delete();
  }
}

final notificationControllerProvider = Provider((ref) => NotificationController());
