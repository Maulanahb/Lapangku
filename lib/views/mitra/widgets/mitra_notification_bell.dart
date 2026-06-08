import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/views/mitra/mitra_notification_page.dart';
import 'package:lapangku/core/services/firestore_service.dart';

class MitraNotificationBell extends ConsumerWidget {
  const MitraNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String uid = ref.watch(currentUidProvider);

    // Fungsi navigasi dipisah agar mudah dipanggil
    void goToNotificationPage() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MitraNotificationPage()),
      );
    }

    // Jika belum login, tampilkan icon button biasa
    if (uid.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications_none, size: 28),
        onPressed: goToNotificationPage,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance
          .collection('notifikasi')
          .where('mitraId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        final String displayText = unreadCount > 9
            ? '9+'
            : unreadCount.toString();

        // TOMBOL UTAMA (Membungkus Stack di dalam properti icon)
        return IconButton(
          onPressed: goToNotificationPage, // KLIK DIJAMIN SELALU AKTIF
          icon: Stack(
            clipBehavior: Clip
                .none, // Agar badge tidak terpotong jika melewati batas icon
            children: [
              // 1. Icon Lonceng
              const Icon(Icons.notifications_none, size: 28),

              // 2. Badge Merah (Hanya muncul jika ada notifikasi)
              if (unreadCount > 0)
                Positioned(
                  right: -2, // Ditarik sedikit ke kanan atas
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
