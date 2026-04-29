import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/features/owner/booking/providers/owner_booking_provider.dart';
import 'package:lapangku/features/owner/field/providers/owner_field_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class OwnerBookingListPage extends ConsumerStatefulWidget {
  const OwnerBookingListPage({super.key});

  @override
  ConsumerState<OwnerBookingListPage> createState() =>
      _OwnerBookingListPageState();
}

class _OwnerBookingListPageState extends ConsumerState<OwnerBookingListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Menunggu'),
    Tab(text: 'Dikonfirmasi'),
    Tab(text: 'Ditolak'),
    Tab(text: 'Selesai'),
  ];

  final _statuses = [
    'menunggu_konfirmasi',
    'dikonfirmasi',
    'ditolak',
    'selesai',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan lapangan sudah di-load
    ref.watch(ownerFieldProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Pesanan Masuk',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses
            .map((status) => _BookingTab(statusFilter: status))
            .toList(),
      ),
    );
  }
}

// ── Tab per status ─────────────────────────────────────────────────
class _BookingTab extends ConsumerWidget {
  final String statusFilter;

  const _BookingTab({required this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync =
        ref.watch(ownerBookingStreamProvider(statusFilter));

    return bookingsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('Gagal memuat: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesanan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF1B6B3A),
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
          ),
        );
      },
    );
  }
}

// ── Card booking ───────────────────────────────────────────────────
class _BookingCard extends ConsumerWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  String _formatDate(DateTime dt) =>
      DateFormat('EEE, d MMM y', 'id').format(dt);

  String _formatRupiah(int amount) =>
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
          .format(amount);

  Color _statusColor(String status) {
    switch (status) {
      case 'menunggu_konfirmasi':
        return Colors.orange;
      case 'dikonfirmasi':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'ditolak':
        return 'Ditolak';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingIds = ref.watch(ownerBookingActionsProvider);
    final isLoading = loadingIds.contains(booking.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B6B3A).withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingId,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1B6B3A)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(booking.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                        color: _statusColor(booking.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person_outline, booking.userName),
                const SizedBox(height: 8),
                _infoRow(Icons.stadium_outlined, booking.fieldName),
                const SizedBox(height: 8),
                _infoRow(Icons.calendar_today_outlined,
                    _formatDate(booking.tanggal)),
                const SizedBox(height: 8),
                _infoRow(Icons.access_time_outlined,
                    booking.timeSlots.join(', ')),
                const SizedBox(height: 8),
                _infoRow(Icons.payments_outlined,
                    _formatRupiah(booking.totalBayar)),

                // Bukti pembayaran
                if (booking.buktiTransferUrl != null) ...[
                  const SizedBox(height: 14),
                  const Text('Bukti Pembayaran',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showImageDialog(context, booking.buktiTransferUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        booking.buktiTransferUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const SizedBox(
                                height: 160,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF1B6B3A)))),
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: Colors.grey.shade100,
                          child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ],

                // Tombol aksi (hanya saat menunggu_konfirmasi)
                if (booking.status == 'menunggu_konfirmasi') ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(
                        child: SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                                color: Color(0xFF1B6B3A), strokeWidth: 2)))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showRejectDialog(context, ref),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Tolak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _confirm(context, ref),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Konfirmasi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B6B3A),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(ownerBookingActionsProvider.notifier)
          .confirmBooking(booking.id);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Pesanan berhasil dikonfirmasi');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Gagal konfirmasi: $e');
      }
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan alasan penolakan (opsional):',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Lapangan sudah penuh',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(ownerBookingActionsProvider.notifier)
                    .rejectBooking(booking.id,
                        reason: reasonController.text.trim());
                if (context.mounted) {
                  SnackbarHelper.showSuccess(context, 'Pesanan ditolak');
                }
              } catch (e) {
                if (context.mounted) {
                  SnackbarHelper.showError(
                      context, 'Gagal menolak: $e');
                }
              }
            },
            child: const Text('Tolak',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
