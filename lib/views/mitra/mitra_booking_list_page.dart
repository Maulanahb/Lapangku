import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/mitra/mitra_booking_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraBookingListPage extends ConsumerStatefulWidget {
  const MitraBookingListPage({super.key});

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _getStatusFilter(int index) {
    switch (index) {
      case 1:
        return 'menunggu_konfirmasi';
      case 2:
        return 'dikonfirmasi';
      case 3:
        return 'selesai';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1B4332)),
          onPressed: () {},
        ),
        title: Row(
          children: [
            const Text(
              'Daftar Pesanan',
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '2 menunggu',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF1B4332)),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF1B4332),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1B4332),
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
              color: const Color(0xFFF3F4F6),
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
                    selectedColor: const Color(0xFF1B6B3A),
                    backgroundColor: const Color(0xFFF3F4F6),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
          return const Center(child: Text('Belum ada pesanan'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              _BookingCard(booking: bookings[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${booking.bookingId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTimeAgo(booking.createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.more_horiz, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: const NetworkImage(
                          'https://i.pravatar.cc/150'), // Placeholder
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '+62 812-3456-7890', // Placeholder as not in model
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stadium_outlined,
                              color: Color(0xFF1B6B3A), size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.fieldName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                DateFormat('EEEE, d MMM yyyy', 'id_ID')
                                    .format(booking.tanggal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Color(0xFF1B6B3A), size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${booking.timeSlots.join(', ')} (${booking.durasi} jam)',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp ',
                                        decimalDigits: 0)
                                    .format(booking.totalBayar),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(booking.metodePembayaran,
                        style: const TextStyle(color: Colors.grey)),
                    const Spacer(),
                    if (booking.buktiTransferUrl != null)
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.link,
                            size: 18, color: Color(0xFF1B6B3A)),
                        label: const Text('Lihat Bukti',
                            style: TextStyle(color: Color(0xFF1B6B3A))),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (booking.status == 'menunggu_konfirmasi')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _onReject(ref),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tolak',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _onConfirm(ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B3A),
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_bayar':
        return Colors.orange;
      case 'menunggu_konfirmasi':
        return Colors.orange;
      case 'dikonfirmasi':
        return Colors.green;
      case 'selesai':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'menunggu_bayar':
        return 'Menunggu Bayar';
      case 'menunggu_konfirmasi':
        return 'Menunggu';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('d MMM').format(date);
  }

  void _onConfirm(WidgetRef ref) async {
    try {
      await ref
          .read(MitraBookingActionsProvider.notifier)
          .confirmBooking(booking.id);
    } catch (e) {
      // Handle error
    }
  }

  void _onReject(WidgetRef ref) async {
    try {
      await ref
          .read(MitraBookingActionsProvider.notifier)
          .rejectBooking(booking.id);
    } catch (e) {
      // Handle error
    }
  }
}
