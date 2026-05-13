import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/mitra/mitra_booking_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/models/booking_status.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/views/mitra/mitra_offline_booking_page.dart';

class MitraBookingListPage extends ConsumerStatefulWidget {
  final int initialIndex;
  const MitraBookingListPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MitraBookingListPage> createState() =>
      _MitraBookingListPageState();
}

class _MitraBookingListPageState extends ConsumerState<MitraBookingListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'Terbaru';
  final List<String> _sortOptions = ['Terbaru', 'Terlama', 'Nilai Tertinggi'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPageAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textBlackSoft),
          onPressed: () {},
        ),
        title: Row(
          children: [
            const Text('Daftar Pesanan',
                style: TextStyle(
                    color: AppColors.textBlackSoft,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusPendingBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ref
                  .watch(MitraBookingStreamProvider('menunggu_konfirmasi'))
                  .when(
                    data: (bookings) => Text(
                      '${bookings.length} menunggu',
                      style: const TextStyle(
                          color: AppColors.statusPendingText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    loading: () => const Text('... menunggu',
                        style: TextStyle(fontSize: 12)),
                    error: (_, __) => const Text('0 menunggu',
                        style: TextStyle(fontSize: 12)),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textBlackSoft),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.textBlackSoft,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.textBlackSoft,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Dikonfirmasi'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(null),
                _buildBookingList('menunggu_konfirmasi'),
                _buildBookingList('dikonfirmasi'),
                _buildBookingList('selesai'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MitraOfflineBookingPage()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Booking Offline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundInputAlt,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau ID pesanan...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sortOptions.map((sort) {
                final isSelected = _selectedSort == sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(sort),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSort = sort);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.backgroundInputAlt,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(String? statusFilter) {
    final bookingsAsync = ref.watch(MitraBookingStreamProvider(statusFilter));

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada pesanan',
            subtitle: 'Pesanan akan muncul di sini',
            iconSize: 64,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              _BookingCard(booking: bookings[index]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(MitraBookingActionsProvider).contains(booking.id);
    // Gunakan BookingStatus — tidak ada _getStatusColor/_getStatusText lagi
    final status = BookingStatusParsing.fromString(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#${booking.bookingId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status.badgeLabel,
                          style: TextStyle(
                              color: status.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(_getTimeAgo(booking.createdAt),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (booking.metodePembayaran == 'offline') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('OFFLINE',
                            style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ]),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _onDelete(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Hapus Log',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      const NetworkImage('https://i.pravatar.cc/150'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('+62 812-3456-7890',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.stadium_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.fieldName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                              DateFormat('EEEE, d MMM yyyy', 'id_ID')
                                  .format(booking.tanggal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.access_time,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${booking.timeSlots.join(', ')} (${booking.durasi} jam)',
                              style: const TextStyle(fontSize: 13)),
                          Text(CurrencyFormatter.format(booking.totalBayar),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(booking.metodePembayaran,
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                if (booking.buktiTransferUrl != null)
                  TextButton.icon(
                    onPressed: () => _showBuktiTransferDialog(context, booking.buktiTransferUrl!),
                    icon: const Icon(Icons.link,
                        size: 18, color: AppColors.primary),
                    label: const Text('Lihat Bukti',
                        style: TextStyle(color: AppColors.primary)),
                  ),
              ]),
            ]),
          ),
          if (booking.isRescheduleRequested && booking.rescheduleStatus == 'pending')
            _buildRescheduleRequestUI(context, ref, booking)
          else if (booking.status == BookingStatus.menungguKonfirmasi.firestoreValue)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => _onReject(ref),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tolak',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : () => _onConfirm(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Konfirmasi',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildRescheduleRequestUI(BuildContext context, WidgetRef ref, BookingModel booking) {
    final isLoading = ref.watch(MitraBookingActionsProvider).contains(booking.id);
    final newDateStr = booking.rescheduleDate != null 
        ? DateFormat('EEEE, d MMM yyyy', 'id_ID').format(booking.rescheduleDate!) 
        : '-';
    final newTimeStr = booking.rescheduleTimeSlots?.join(', ') ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_calendar, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              Text('Pengajuan Reschedule', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tanggal Baru:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(newDateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jam Baru:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(newTimeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Divider(height: 20),
                const Text('Alasan:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(booking.rescheduleReason ?? '-', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : () async {
                    try {
                      await ref.read(MitraBookingActionsProvider.notifier).rejectReschedule(booking.id);
                      if (context.mounted) SnackbarHelper.showSuccess(context, 'Pengajuan reschedule ditolak');
                    } catch (e) {
                      if (context.mounted) SnackbarHelper.showError(context, 'Gagal: $e');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade800),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tolak', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    try {
                      await ref.read(MitraBookingActionsProvider.notifier).approveReschedule(booking.id);
                      if (context.mounted) SnackbarHelper.showSuccess(context, 'Pengajuan reschedule disetujui');
                    } catch (e) {
                      if (context.mounted) SnackbarHelper.showError(context, 'Gagal: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('d MMM').format(date);
  }

  void _onConfirm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConfirmationSheet(
        booking: booking,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await ref
                .read(MitraBookingActionsProvider.notifier)
                .confirmBooking(booking.id);
          } catch (_) {}
        },
      ),
    );
  }

  void _onReject(WidgetRef ref) async {
    try {
      await ref
          .read(MitraBookingActionsProvider.notifier)
          .rejectBooking(booking.id);
    } catch (_) {}
  }

  void _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Log Pesanan?'),
        content: const Text(
            'Tindakan ini akan menghapus riwayat pesanan secara permanen dari daftar Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(MitraBookingActionsProvider.notifier)
            .deleteBooking(booking.id);
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'Log pesanan berhasil dihapus');
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Gagal menghapus log: $e');
        }
      }
    }
  }

  void _showBuktiTransferDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onConfirm;

  const _ConfirmationSheet({required this.booking, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Konfirmasi Pesanan?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlackSoft,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pastikan bukti pembayaran valid sebelum menyetujui pesanan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildInfoRow('Pelanggan', booking.userName, isBold: true),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Layanan', '${booking.fieldName} (${booking.durasi} Jam)'),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Total Bayar', CurrencyFormatter.format(booking.totalBayar),
                    isPrice: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFE9EFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.textBlackSoft,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5A3C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ya, Konfirmasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold || isPrice ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            color: isPrice ? const Color(0xFF0F5A3C) : AppColors.textBlackSoft,
          ),
        ),
      ],
    );
  }
}
