import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/notification/notification_controller.dart';
import 'package:lapangku/models/notification/notification_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';

class MitraNotificationPage extends ConsumerWidget {
  const MitraNotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(mitraNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Notifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Tandai Semua Sudah Dibaca',
            onPressed: () async {
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                LoadingOverlay.show(context, message: 'Menandai...');
                await ref.read(notificationControllerProvider).markAllMitraAsRead(user.uid);
                if (context.mounted) LoadingOverlay.dismiss(context);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'Belum ada notifikasi',
              subtitle: 'Kamu akan melihat notifikasi di sini saat ada pembaruan.',
            );
          }

          final today = <NotificationModel>[];
          final yesterday = <NotificationModel>[];
          final older = <NotificationModel>[];

          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);
          final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

          for (var notif in notifications) {
            final date = DateTime(notif.createdAt.year, notif.createdAt.month, notif.createdAt.day);
            if (date == startOfToday) {
              today.add(notif);
            } else if (date == startOfYesterday) {
              yesterday.add(notif);
            } else {
              older.add(notif);
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mitraNotificationsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (today.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...today.map((n) => _NotificationCard(notification: n)),
                ],
                if (yesterday.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Kemarin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...yesterday.map((n) => _NotificationCard(notification: n)),
                ],
                if (older.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Sebelumnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...older.map((n) => _NotificationCard(notification: n)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      if (minutes <= 0) return 'BARU SAJA';
      return '$minutes MENIT YANG LALU';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} JAM YANG LALU';
    } else {
      final isYesterday = now.year == dateTime.year && now.month == dateTime.month && now.day - dateTime.day == 1;
      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      if (isYesterday) {
        return 'KEMARIN, $timeStr';
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} $timeStr';
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'booking': return Icons.check_circle;
      case 'payment': return Icons.payment;
      case 'promo': return Icons.local_offer;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'booking': return Colors.green;
      case 'payment': return Colors.red;
      case 'promo': return Colors.orange;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        return ConfirmationDialog.show(
          context: context,
          title: 'Hapus Notifikasi',
          message: 'Yakin ingin menghapus notifikasi ini?',
          confirmText: 'Hapus',
          isDestructive: true,
        );
      },
      onDismissed: (direction) {
        ref.read(notificationControllerProvider).deleteNotification(notification.id);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await ref.read(notificationControllerProvider).markAsRead(notification.id);
          }
          if (!context.mounted) return;
          
          if (notification.type == 'booking') {
            Navigator.pushNamed(context, '/mitra-orders');
          } else if (notification.type == 'payment') {
            Navigator.pushNamed(context, '/mitra-orders');
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_getIcon(), color: _getIconColor(), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(notification.message, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text(_formatRelativeTime(notification.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
