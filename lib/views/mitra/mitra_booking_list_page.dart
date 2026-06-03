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
import 'package:lapangku/core/services/firestore_service.dart';

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
  
  // Pagination state
  int _currentPage = 1;
  final int _itemsPerPage = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _currentPage = 1);
      }
    });
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Text(
              'Daftar Pesanan',
              style: TextStyle(
                color: Color(0xFF0F4C36),
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            ref.watch(MitraBookingStreamProvider('menunggu_konfirmasi')).when(
                  data: (bookings) => bookings.isEmpty 
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${bookings.length} menunggu',
                          style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F4C36)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
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
                _buildBookingList('semua'),
                _buildBookingList('menunggu'),
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
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Booking Offline',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 1),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Cari nama pelanggan atau ID...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sortOptions.length,
              itemBuilder: (context, index) {
                final sort = _sortOptions[index];
                final isSelected = _selectedSort == sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedSort = sort;
                      _currentPage = 1;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        sort,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildBookingList(String filterKey) {
    // Selalu fetch semua booking, lalu filter di lokal agar efisien & mendukung logika OR
    final bookingsAsync = ref.watch(MitraBookingStreamProvider(null));

    return bookingsAsync.when(
      data: (bookings) {
        final filteredBookings = bookings.where((b) {
          // 1. Text Search Filter
          final query = _searchController.text.toLowerCase();
          final matchesSearch = b.userName.toLowerCase().contains(query) ||
              b.bookingId.toLowerCase().contains(query);
          if (!matchesSearch) return false;

          // 2. Tab Filter
          final status = b.status.toLowerCase();
          if (filterKey == 'menunggu') {
            return status == 'menunggu_konfirmasi' || (b.isRescheduleRequested && b.rescheduleStatus == 'pending');
          } else if (filterKey == 'dikonfirmasi') {
            return status == 'dikonfirmasi' && !(b.isRescheduleRequested && b.rescheduleStatus == 'pending');
          } else if (filterKey == 'selesai') {
            return status == 'selesai';
          }
          return true; // 'semua'
        }).toList();

        switch (_selectedSort) {
          case 'Terbaru':
            filteredBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case 'Terlama':
            filteredBookings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case 'Nilai Tertinggi':
            filteredBookings
                .sort((a, b) => b.totalBayar.compareTo(a.totalBayar));
            break;
        }

        if (filteredBookings.isEmpty) {
          return EmptyStateWidget(
            icon: _searchController.text.isEmpty
                ? Icons.receipt_long_outlined
                : Icons.search_off_outlined,
            title: _searchController.text.isEmpty
                ? 'Belum ada pesanan'
                : 'Tidak ditemukan',
            subtitle: _searchController.text.isEmpty
                ? 'Pesanan akan muncul di sini'
                : 'Coba kata kunci atau filter lain',
            iconSize: 64,
          );
        }

        final int totalPages = (filteredBookings.length / _itemsPerPage).ceil();
        
        // Safety check if search reduces items such that currentPage is out of bounds
        final safePage = (_currentPage > totalPages && totalPages > 0) ? 1 : _currentPage;

        final paginatedBookings = filteredBookings
            .skip((safePage - 1) * _itemsPerPage)
            .take(_itemsPerPage)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: paginatedBookings.length + (totalPages > 1 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == paginatedBookings.length) {
              return _buildPaginationControls(totalPages, safePage);
            }
            return _BookingCard(booking: paginatedBookings[index]);
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPaginationControls(int totalPages, int currentPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 1 ? () => setState(() => _currentPage = currentPage - 1) : null,
            child: Icon(Icons.chevron_left_rounded, color: currentPage > 1 ? AppColors.primary : Colors.grey.shade300),
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages, (index) {
            final page = index + 1;

            if (totalPages > 5) {
              if (page != 1 && page != totalPages && (page < currentPage - 1 || page > currentPage + 1)) {
                if (page == currentPage - 2 || page == currentPage + 2) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('···', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                }
                return const SizedBox.shrink();
              }
            }

            final isSelected = page == currentPage;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = page),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: currentPage < totalPages ? () => setState(() => _currentPage = currentPage + 1) : null,
            child: Icon(Icons.chevron_right_rounded, color: currentPage < totalPages ? AppColors.primary : Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}

final _userInfoProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) async {
  if (userId.isEmpty || userId.startsWith('offline_')) return null;
  try {
    final doc = await FirestoreService.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
  } catch (e) {
    debugPrint('🚨 ERROR FETCH USER INFO untuk $userId: $e');
  }
  return null;
});

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(MitraBookingActionsProvider).contains(booking.id);
    final status = BookingStatusParsing.fromString(booking.status);
    final userInfoAsync = ref.watch(_userInfoProvider(booking.userId));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
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
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.badgeLabel.toUpperCase(),
                                style: TextStyle(color: status.color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTimeAgo(booking.createdAt),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (booking.metodePembayaran == 'offline')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text('OFFLINE', style: TextStyle(color: Colors.purple.shade700, fontSize: 10, fontWeight: FontWeight.w900)),
                      )
                    else
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
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
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Hapus Log', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Builder(
                        builder: (context) {
                          final fetchedAvatar = userInfoAsync.asData?.value?['avatarUrl']?.toString() ?? userInfoAsync.asData?.value?['photoUrl']?.toString();
                          final avatarUrl = fetchedAvatar ?? booking.userAvatarUrl;
                          
                          final initials = booking.userName.trim().isNotEmpty
                              ? booking.userName
                                  .trim()
                                  .split(' ')
                                  .where((l) => l.isNotEmpty)
                                  .map((l) => l[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                              : 'U';

                          Widget buildPlaceholder() => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF5FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF1E40AF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );

                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                width: 48,
                                height: 48,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('🚨 ERROR RENDER IMAGE NETWORK: $error');
                                  return buildPlaceholder();
                                },
                              ),
                            );
                          }

                          if (userInfoAsync.isLoading) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          return buildPlaceholder();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          userInfoAsync.when(
                            data: (userInfo) {
                              final phone = userInfo?['phone']?.toString();
                              if (phone != null && phone.isNotEmpty) {
                                return Text(phone, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12));
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const Text('Memuat...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEF2FF)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.stadium_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking.fieldName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, d MMM yyyy', 'id_ID').format(booking.tanggal),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFE0E7FF)),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.timeSlots.join(', ')} (${booking.durasi} jam)',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(booking.totalBayar),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      booking.metodePembayaran.toLowerCase() == 'qris' ? Icons.qr_code_2_rounded : Icons.account_balance_wallet_outlined,
                      size: 16, 
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(booking.metodePembayaran.toUpperCase(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const Spacer(),
                    if (booking.buktiTransferUrl != null)
                      GestureDetector(
                        onTap: () => _showBuktiTransferDialog(context, booking.buktiTransferUrl!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.image_outlined, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Bukti Bayar', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (booking.status == BookingStatus.menungguKonfirmasi.firestoreValue)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _onReject(context, ref),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFDA4AF)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Tolak', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _onConfirm(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Konfirmasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          if (booking.isRescheduleRequested && booking.rescheduleStatus == 'pending' && booking.status == BookingStatus.dikonfirmasi.firestoreValue)
            _buildRescheduleRequestUI(context, ref, booking),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: Color(0xFFC2410C), size: 20),
              SizedBox(width: 8),
              Text('Pengajuan Reschedule', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A3412), fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFEDD5))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRescheduleRow('Tanggal Baru', newDateStr),
                const SizedBox(height: 8),
                _buildRescheduleRow('Jam Baru', newTimeStr),
                const Divider(height: 24, color: Color(0xFFFFEDD5)),
                const Text('Alasan:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(booking.rescheduleReason ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontStyle: FontStyle.italic)),
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
                    side: const BorderSide(color: Color(0xFFFDBA74)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Tolak', style: TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.w800)),
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
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
      ],
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
            if (context.mounted) {
              SnackbarHelper.showSuccess(context, 'Booking berhasil dikonfirmasi');
            }
          } catch (e) {
            if (context.mounted) {
              SnackbarHelper.showError(context, 'Gagal mengkonfirmasi: $e');
            }
          }
        },
      ),
    );
  }

  void _onReject(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(MitraBookingActionsProvider.notifier)
          .rejectBooking(booking.id);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Booking berhasil ditolak');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Gagal menolak: $e');
      }
    }
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
