// lib/views/Mitra/mitra_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_stats_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_booking_provider.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/views/mitra/mitra_booking_list_page.dart';
import 'package:lapangku/views/mitra/widgets/mitra_notification_bell.dart';
import 'package:intl/intl.dart';

class MitraHomePage extends ConsumerStatefulWidget {
  const MitraHomePage({super.key});

  @override
  ConsumerState<MitraHomePage> createState() => _MitraHomePageState();
}

class _MitraHomePageState extends ConsumerState<MitraHomePage> {
  final Color _primaryGreen = const Color(0xFF0F5A3C);
  final Color _bgLightGreen = const Color(0xFFE8F5EF);
  final Color _bgLightRed = const Color(0xFFFEE8E7);
  final Color _textRed = const Color(0xFFE04443);
  String? _selectedBarDay;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String get _uid => ref.watch(currentUidProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 32),
                      _buildWaitingListHeader(),
                      const SizedBox(height: 16),
                      _buildWaitingOrderCard(),
                      const SizedBox(height: 32),
                      _buildRevenueSummarySection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            ref.watch(mitraProfileProvider).when(
                  data: (profile) => CircleAvatar(
                    key: ValueKey(profile.logoUrl),
                    radius: 20,
                    backgroundColor: _bgLightGreen,
                    backgroundImage:
                        profile.logoUrl != null && profile.logoUrl!.isNotEmpty
                            ? NetworkImage(profile.logoUrl!)
                            : null,
                    child: profile.logoUrl == null || profile.logoUrl!.isEmpty
                        ? Text(
                            _getInitials(profile.businessName),
                            style: TextStyle(
                              color: _primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  loading: () => CircleAvatar(
                    radius: 20,
                    backgroundColor: _bgLightGreen,
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0F5A3C)),
                    ),
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 20,
                    backgroundColor: _bgLightGreen,
                    child: Icon(Icons.person, color: _primaryGreen, size: 20),
                  ),
                ),

            const SizedBox(width: 12),
            Text('LapangKu',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _primaryGreen)),
          ]),
          const MitraNotificationBell(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();

    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final String currentDate =
        '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Dashboard',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
      const SizedBox(height: 4),
      Text(currentDate,
          style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildStatsGrid() {
    final todayStats = ref.watch(mitraTodayStatsProvider(_uid));
    final monthlyStats = ref.watch(mitraMonthlyStatsProvider(_uid));
    final fieldsAsync = ref.watch(mitraFieldProvider).fields;
    final waitingBookings = ref.watch(mitraWaitingBookingsProvider(_uid));

    int activeCount = 0;
    int totalCount = 0;
    double avgRating = 0.0;
    int ratedFields = 0;
    int totalReviewCount = 0;

    fieldsAsync.whenData((fields) {
      activeCount = fields.where((f) => f.isActive).length;
      totalCount = fields.length;
      double totalRating = 0;
      for (var field in fields) {
        if (field.totalReviews > 0) {
          totalRating += field.avgRating;
          ratedFields++;
        }
        totalReviewCount += field.totalReviews;
      }
      avgRating = ratedFields > 0 ? totalRating / ratedFields : 0.0;
    });

    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.assignment_outlined,
              iconBgColor: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF6366F1),
              label: 'Pesanan Hari Ini',
              value: '${todayStats['count']}',
              footer: '${todayStats['confirmedCount'] ?? 0} dikonfirmasi',
              badge: waitingBookings.isNotEmpty
                  ? '${waitingBookings.length} menunggu'
                  : null,
              badgeColor: const Color(0xFFFEF3C7),
              badgeTextColor: const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBgColor: _bgLightGreen,
              iconColor: _primaryGreen,
              label: 'Pendapatan Hari Ini',
              value: todayStats['revenue'] >= 1000000
                  ? 'Rp ${(todayStats['revenue'] / 1000000).toStringAsFixed(1)}M'
                  : _currencyFormat.format(todayStats['revenue']),
              valueColor: _primaryGreen,
              footer: 'Bulan ini: ${monthlyStats['revenue'] >= 1000000 ? '${(monthlyStats['revenue'] / 1000000).toStringAsFixed(1)}M' : _currencyFormat.format(monthlyStats['revenue'])}',
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.stadium_rounded,
              iconBgColor: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFEA580C),
              label: 'Lapangan Aktif',
              value: fieldsAsync.isLoading ? '...' : '$activeCount / $totalCount',
              footer: fieldsAsync.isLoading
                  ? 'Memuat...'
                  : '${monthlyStats['totalBookings']} booking bulan ini',
              progressValue: totalCount > 0 ? activeCount / totalCount : 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              iconBgColor: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFD97706),
              label: 'Rating Rata-rata',
              value: fieldsAsync.isLoading ? '...' : avgRating.toStringAsFixed(1),
              hasStar: true,
              footer: fieldsAsync.isLoading
                  ? 'Memuat...'
                  : '$totalReviewCount ulasan · $ratedFields lapangan',
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildStatCard(
      {required String label,
      required String value,
      required String footer,
      IconData? icon,
      Color? iconBgColor,
      Color? iconColor,
      Color? valueColor,
      bool hasStar = false,
      String? badge,
      Color? badgeColor,
      Color? badgeTextColor,
      double? progressValue}) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return GestureDetector(
          onTapDown: (_) => setLocalState(() => isPressed = true),
          onTapUp: (_) => setLocalState(() => isPressed = false),
          onTapCancel: () => setLocalState(() => isPressed = false),
          onLongPress: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPressed ? const Color(0xFFF6FBF8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPressed
                    ? _primaryGreen.withOpacity(0.3)
                    : Colors.grey[100]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: isPressed
                        ? _primaryGreen.withOpacity(0.18)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: isPressed ? 18 : 10,
                    spreadRadius: isPressed ? 2 : 0,
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconBgColor ?? _bgLightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 15, color: iconColor ?? _primaryGreen),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600])),
                ),
              ]),
              const SizedBox(height: 10),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(value,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: valueColor ?? Colors.black),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (hasStar) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 16)
                    ],
                  ]),
              if (progressValue != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: _primaryGreen,
                    minHeight: 4,
                  ),
                ),
              ],
              if (badge != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor ?? const Color(0xFFD97706))),
                ),
              ],
              if (footer.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(footer,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500))
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _buildWaitingListHeader() {
    final waitingBookings = ref.watch(mitraWaitingBookingsProvider(_uid));

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        const Text('Pesanan Menunggu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        if (waitingBookings.isNotEmpty)
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEE8E7),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${waitingBookings.length}',
                  style: const TextStyle(
                      color: Color(0xFFE04443),
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
      ]),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MitraBookingListPage(initialIndex: 1),
            ),
          );
        },
        child: Row(children: [
          Text('Lihat Semua',
              style: TextStyle(
                  color: _primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Icon(Icons.arrow_forward, color: _primaryGreen, size: 16),
        ]),
      ),
    ]);
  }

  Widget _buildWaitingOrderCard() {
    final waitingBookings = ref.watch(mitraWaitingBookingsProvider(_uid));

    if (waitingBookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pesanan menunggu',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final booking = waitingBookings.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.02)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _primaryGreen.withOpacity(0.1),
            backgroundImage: booking.userAvatarUrl != null && booking.userAvatarUrl!.isNotEmpty 
                ? NetworkImage(booking.userAvatarUrl!) 
                : null,
            child: booking.userAvatarUrl == null || booking.userAvatarUrl!.isEmpty
                ? Text(
                    booking.userName.isNotEmpty ? booking.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                        color: _primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(booking.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(booking.bookingId,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13))
                ]),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(_getTimeAgo(booking.createdAt),
                  style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        if (booking.isRescheduleRequested && booking.rescheduleStatus == 'pending') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_calendar_rounded, color: Color(0xFFEA580C), size: 14),
                SizedBox(width: 6),
                Text('PENGAJUAN RESCHEDULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF9A3412))),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5FE),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: _primaryGreen),
                const SizedBox(width: 8),
                Text(booking.fieldName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('  •  ', style: TextStyle(color: Colors.grey)),
                Text(DateFormat('EEE, d MMM', 'id').format(booking.tanggal),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500))
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.access_time, size: 16, color: _primaryGreen),
                const SizedBox(width: 8),
                Text(booking.timeSlots.join(', '),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500))
              ]),
            ])),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Pembayaran',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(_currencyFormat.format(booking.totalBayar),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(booking.metodePembayaran,
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 20),
        _buildActionButtons(booking),
      ]),
    );
  }

  // Baris yang sebelumnya error sekarang sudah aman jika BookingModel di-import dengan benar
  Widget _buildActionButtons(BookingModel booking) {
    final bookingId = booking.id;
    final isMutating =
        ref.watch(MitraBookingActionsProvider).contains(bookingId);
    
    final isReschedule = booking.isRescheduleRequested && booking.rescheduleStatus == 'pending';

    return Row(children: [
      Expanded(
        child: ElevatedButton(
          onPressed: isMutating ? null : () => isReschedule ? _handleRejectReschedule(bookingId) : _handleReject(bookingId),
          style: ElevatedButton.styleFrom(
            backgroundColor: _bgLightRed,
            foregroundColor: _textRed,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(isReschedule ? 'Tolak' : 'Tolak',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: isMutating ? null : () => isReschedule ? _handleApproveReschedule(bookingId) : _handleConfirm(bookingId),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: isMutating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isReschedule ? 'Konfirmasi' : 'Konfirmasi',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ),
    ]);
  }

  Future<void> _handleConfirm(String id) async {
    try {
      await ref.read(MitraBookingActionsProvider.notifier).confirmBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dikonfirmasi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(String id) async {
    try {
      await ref.read(MitraBookingActionsProvider.notifier).rejectBooking(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil ditolak')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak: $e')),
        );
      }
    }
  }

  Future<void> _handleApproveReschedule(String id) async {
    try {
      await ref.read(MitraBookingActionsProvider.notifier).approveReschedule(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule berhasil disetujui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyetujui: $e')),
        );
      }
    }
  }

  Future<void> _handleRejectReschedule(String id) async {
    try {
      await ref.read(MitraBookingActionsProvider.notifier).rejectReschedule(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule berhasil ditolak')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak: $e')),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  Widget _buildRevenueSummarySection() {
    final weeklyData = ref.watch(mitraRevenueWeeklyProvider(_uid));

    int totalWeekly = 0;
    for (var data in weeklyData) {
      totalWeekly += data['revenue'] as int;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ringkasan Pendapatan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pendapatan 7 Hari Terakhir',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
              totalWeekly >= 1000000
                  ? 'Rp ${(totalWeekly / 1000000).toStringAsFixed(1)} Juta'
                  : _currencyFormat.format(totalWeekly),
              style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          StatefulBuilder(
            builder: (context, setBarState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeklyData.isEmpty
                    ? List.generate(7, (index) => _buildMiniBar('-', 0.1, revenue: 0, selectedDay: _selectedBarDay, onTap: (d) => setBarState(() => _selectedBarDay = _selectedBarDay == d ? null : d)))
                    : weeklyData.map((data) {
                        double maxRevenue = 0;
                        for (var d in weeklyData) {
                          if (d['revenue'] > maxRevenue) {
                            maxRevenue = d['revenue'].toDouble();
                          }
                        }
                        double factor =
                            maxRevenue > 0 ? (data['revenue'] / maxRevenue) : 0.1;
                        if (factor < 0.1) factor = 0.1;

                        return _buildMiniBar(
                          data['day'],
                          factor,
                          isToday: data['isToday'],
                          revenue: data['revenue'] as int,
                          selectedDay: _selectedBarDay,
                          onTap: (day) => setBarState(() => _selectedBarDay = _selectedBarDay == day ? null : day),
                        );
                      }).toList(),
              );
            },
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMiniBar(String day, double heightFactor,
      {bool isToday = false, int revenue = 0, String? selectedDay, Function(String)? onTap}) {
    final bool isSelected = selectedDay == day;
    final bool showTooltip = isSelected || (isToday && selectedDay == null);
    
    String revenueText;
    if (revenue >= 1000000) {
      revenueText = '${(revenue / 1000000).toStringAsFixed(1)}M';
    } else if (revenue >= 1000) {
      revenueText = '${(revenue / 1000).toStringAsFixed(0)}K';
    } else {
      revenueText = _currencyFormat.format(revenue);
    }

    return GestureDetector(
      onTap: () => onTap?.call(day),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: showTooltip ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected ? _primaryGreen : (isToday ? const Color(0xFFD1FAE5) : _primaryGreen),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
                isToday && !isSelected ? 'Today' : revenueText,
                style: TextStyle(
                    color: isSelected ? Colors.white : (isToday ? Colors.black : Colors.white),
                    fontWeight: FontWeight.bold,
                    fontSize: 9)),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: isSelected ? 18 : 12,
          height: 80 * heightFactor,
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryGreen
                : isToday
                    ? _primaryGreen
                    : Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day,
            style: TextStyle(
              fontSize: 11,
              fontWeight: (isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
              color: (isToday || isSelected) ? _primaryGreen : Colors.grey[500],
            )),
      ]),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'MT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.length >= 3
        ? name.substring(0, 3).toUpperCase()
        : name.toUpperCase();
  }
}