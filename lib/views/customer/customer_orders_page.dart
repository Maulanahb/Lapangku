import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/views/customer/payment_upload_page.dart';

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({super.key});
  @override
  ConsumerState<CustomerOrdersPage> createState() => _State();
}

class _State extends ConsumerState<CustomerOrdersPage> {
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Menunggu Bayar', 'Aktif', 'Menunggu', 'Selesai', 'Dibatalkan'];

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<BookingModel> bookings) {
    setState(() {
      if (_selectedIds.length == bookings.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(bookings.map((b) => b.id));
      }
    });
  }

  Future<void> _deleteSelected(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pesanan?'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedIds.length} pesanan dari riwayat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = ref.read(bookingServiceProvider);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
      );
    }

    try {
      final futures = _selectedIds.map((id) => service.deleteBooking(id));
      await Future.wait(futures);
      
      ref.invalidate(userBookingsProvider(userId));
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} pesanan berhasil dihapus'),
            backgroundColor: const Color(0xFF1B6B3A),
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    if (user == null) return _loginPrompt();

    final bookingsAsync = ref.watch(userBookingsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B6B3A),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (user != null)
            bookingsAsync.maybeWhen(
              data: (bookings) {
                if (bookings.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: _toggleSelectionMode,
                  child: Text(
                    _isSelectionMode ? 'Batal' : 'Pilih',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.invalidate(userBookingsProvider(user.uid)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
              error: (e, _) => Center(child: Text('Gagal memuat pesanan:\n$e', textAlign: TextAlign.center)),
              data: (bookings) => _buildBookingList(bookings, user.uid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPrompt() => const Scaffold(
    backgroundColor: Color(0xFFF4F6F9),
    body: Center(child: Text('Silakan login untuk melihat pesanan', style: TextStyle(color: Color(0xFF718096)))),
  );

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1B6B3A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? const Color(0xFF1B6B3A) : Colors.grey.shade300),
                ),
                child: Text(f, style: TextStyle(
                  fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  color: sel ? Colors.white : const Color(0xFF718096),
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, String userId) {
    // Filter berdasarkan status
    final filtered = _filter == 'Semua'
        ? bookings
        : bookings.where((b) {
            final status = b.status.toLowerCase();
            final filterKey = _filter.toLowerCase();
            if (filterKey == 'menunggu bayar') return status == 'menunggu_bayar';
            if (filterKey == 'aktif') return status == 'dikonfirmasi' || status == 'aktif';
            if (filterKey == 'menunggu') return status == 'menunggu_konfirmasi';
            return status == filterKey;
          }).toList();

    if (filtered.isEmpty) return _buildEmpty();

    return Column(
      children: [
        if (_isSelectionMode)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedIds.length == filtered.length && filtered.isNotEmpty,
                  onChanged: (_) => _selectAll(filtered),
                  activeColor: const Color(0xFF1B6B3A),
                ),
                const Text('Pilih Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _deleteSelected(userId),
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text('Hapus (${_selectedIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final booking = filtered[i];
              return _BookingCard(
                booking: booking,
                onCancel: () => _cancelBooking(booking.id, userId),
                onRefresh: () => ref.invalidate(userBookingsProvider(userId)),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedIds.contains(booking.id),
                onSelect: () => _toggleSelection(booking.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('Belum ada pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        const SizedBox(height: 8),
        Text(
          _filter == 'Semua' ? 'Pesanan Anda akan muncul di sini' : 'Tidak ada pesanan dengan status "$_filter"',
          style: const TextStyle(color: Color(0xFF718096)),
        ),
      ]),
    );
  }

  Future<void> _cancelBooking(String bookingId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = ref.read(bookingServiceProvider);
      await service.cancelBooking(bookingId);
      ref.invalidate(userBookingsProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pesanan berhasil dibatalkan'),
          backgroundColor: Color(0xFF1B6B3A),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// â”€â”€ BOOKING CARD â”€â”€
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const _BookingCard({
    required this.booking, 
    required this.onCancel, 
    required this.onRefresh,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(booking.status);
    final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.isNotEmpty ? booking.timeSlots.first : '-';

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          onSelect?.call();
        } else {
          Navigator.pushNamed(context, '/booking-detail', arguments: booking.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: const Color(0xFF1B6B3A), width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID + Status
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (_) => onSelect?.call(),
                              activeColor: const Color(0xFF1B6B3A),
                            ),
                          ),
                        ),
                      Text('#${booking.bookingId}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(statusInfo['label'] as String,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusInfo['textColor'] as Color)),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EC), 
                      borderRadius: BorderRadius.circular(12),
                      image: booking.fieldImageUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(booking.fieldImageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: booking.fieldImageUrl.isEmpty ? const Center(child: Icon(Icons.sports_soccer, size: 28, color: Color(0xFF1B6B3A))) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(booking.fieldName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF718096)),
                        const SizedBox(width: 4),
                        Expanded(child: Text('$dateStr Â· $timeStr', style: const TextStyle(fontSize: 12, color: Color(0xFF718096)))),
                      ]),
                    ]),
                  ),
                ],
              ),
            ),
            // Footer: Harga + Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('TOTAL BAYAR', style: TextStyle(fontSize: 9, color: Color(0xFF718096), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(booking.totalBayar),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
                  ]),
                  const Spacer(),
                  // Action buttons based on status
                  ..._buildActions(context, booking.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_bayar':
        return [
          _actionBtn(Icons.payment, 'Bayar', const Color(0xFFD97706), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentUploadPage(booking: booking)));
          }),
          const SizedBox(width: 8),
          _actionBtn(Icons.close, 'Batal', Colors.red.shade400, onCancel),
        ];
      case 'menunggu_konfirmasi':
        return [
          _actionBtn(Icons.close, 'Batalkan', Colors.red.shade400, onCancel),
        ];
      case 'dikonfirmasi':
      case 'aktif':
        return [
          _actionBtn(Icons.confirmation_num_outlined, 'Lihat Tiket', const Color(0xFF1B6B3A), () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur tiket segera hadir!'), backgroundColor: Color(0xFF1B6B3A)));
          }),
        ];
      case 'selesai':
        return [
          _actionBtn(Icons.star_outline, 'Beri Ulasan', Colors.amber.shade700, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ulasan segera hadir!'), backgroundColor: Color(0xFF1B6B3A)));
          }),
        ];
      default:
        return [];
    }
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_bayar':
        return {'label': 'MENUNGGU PEMBAYARAN', 'bgColor': const Color(0xFFFEF3C7), 'textColor': Colors.orange.shade800};
      case 'menunggu_konfirmasi':
        return {'label': 'MENUNGGU KONFIRMASI', 'bgColor': const Color(0xFFEBF8FF), 'textColor': const Color(0xFF2B6CB0)};
      case 'dikonfirmasi':
      case 'aktif':
        return {'label': 'AKTIF', 'bgColor': const Color(0xFFD1FAE5), 'textColor': const Color(0xFF1B6B3A)};
      case 'selesai':
        return {'label': 'SELESAI', 'bgColor': const Color(0xFFE0E7FF), 'textColor': Colors.indigo};
      case 'dibatalkan':
        return {'label': 'DIBATALKAN', 'bgColor': const Color(0xFFFEE2E2), 'textColor': Colors.red.shade700};
      default:
        return {'label': status.toUpperCase(), 'bgColor': Colors.grey.shade100, 'textColor': Colors.grey};
    }
  }
}
