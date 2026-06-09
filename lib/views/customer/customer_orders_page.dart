import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase_storage_service.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lapangku/services/firebase/review_service.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/models/booking_status.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';
import 'package:lapangku/standards/widgets/shimmer_loading.dart';

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({super.key});
  @override
  ConsumerState<CustomerOrdersPage> createState() => _State();
}

class _State extends ConsumerState<CustomerOrdersPage> {
  String _filter = 'Semua';
  final ScrollController _filterScrollController = ScrollController();
  final List<String> _filters = [
    'Semua',
    'Menunggu Bayar',
    'Aktif',
    'Menunggu',
    'Selesai',
    'Dibatalkan'
  ];

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
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
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Hapus Pesanan?',
      message:
          'Apakah Anda yakin ingin menghapus ${_selectedIds.length} pesanan dari riwayat?',
      confirmText: 'Hapus',
      isDestructive: true,
    );
    if (!confirm) return;

    final service = ref.read(bookingServiceProvider);

    if (mounted) LoadingOverlay.show(context);

    try {
      final futures =
          _selectedIds.map((id) => service.hideBookingForCustomer(id));
      await Future.wait(futures);

      ref.invalidate(userBookingsStreamProvider(userId));

      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} pesanan berhasil dihapus'),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _setFilter(String filter, int index) {
    setState(() => _filter = filter);
    if (!_filterScrollController.hasClients) return;

    final targetOffset = (index * 96.0) - 24.0;
    final maxOffset = _filterScrollController.position.maxScrollExtent;
    _filterScrollController.animateTo(
      targetOffset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  String _effectiveStatusValue(BookingModel booking) {
    if (booking.isRescheduleRequested &&
        booking.rescheduleStatus == 'pending') {
      return BookingStatus.menungguKonfirmasi.firestoreValue;
    }
    return booking.status;
  }

  bool _matchesFilter(BookingModel booking) {
    if (_filter == 'Semua') return true;

    final status =
        BookingStatusParsing.fromString(_effectiveStatusValue(booking));

    switch (_filter) {
      case 'Menunggu Bayar':
        return status == BookingStatus.menungguBayar;
      case 'Menunggu':
        return status == BookingStatus.menungguKonfirmasi;
      case 'Aktif':
        return status == BookingStatus.dikonfirmasi ||
            status == BookingStatus.aktif;
      case 'Selesai':
        return status == BookingStatus.selesai;
      case 'Dibatalkan':
        return status == BookingStatus.dibatalkan ||
            status == BookingStatus.ditolak ||
            status == BookingStatus.expired;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    if (user == null) return _loginPrompt();

    final bookingsAsync = ref.watch(userBookingsStreamProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text('Pesanan Saya',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          bookingsAsync.maybeWhen(
            data: (bookings) {
              if (bookings.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _toggleSelectionMode,
                child: Text(
                  _isSelectionMode ? 'Batal' : 'Pilih',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: bookingsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => ShimmerLoading.listTile(),
              ),
              error: (e, _) => Center(
                  child: Text('Gagal memuat pesanan:\n$e',
                      textAlign: TextAlign.center)),
              data: (bookings) => _buildBookingList(bookings, user.uid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPrompt() => const Scaffold(
        backgroundColor: AppColors.backgroundPage,
        body: Center(
          child: Text(
            'Silakan login untuk melihat pesanan',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.builder(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _setFilter(f, i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppColors.primary : Colors.grey.shade300),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                    color: sel ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, String userId) {
    final filtered =
        _filter == 'Semua' ? bookings : bookings.where(_matchesFilter).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userBookingsStreamProvider(userId));
          try {
            await ref.read(userBookingsStreamProvider(userId).future);
          } catch (_) {}
        },
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada pesanan',
                subtitle: _filter == 'Semua'
                    ? 'Pesanan Anda akan muncul di sini'
                    : 'Tidak ada pesanan dengan status "$_filter"',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isSelectionMode)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedIds.length == filtered.length &&
                      filtered.isNotEmpty,
                  onChanged: (_) => _selectAll(filtered),
                  activeColor: AppColors.primary,
                ),
                const Text('Pilih Semua',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _deleteSelected(userId),
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text('Hapus (${_selectedIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userBookingsStreamProvider(userId));
              try {
                await ref.read(userBookingsStreamProvider(userId).future);
              } catch (_) {}
            },
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final booking = filtered[i];
                return _BookingCard(
                  booking: booking,
                  onCancel: () => _cancelBooking(booking.id, userId),
                  onRefresh: () =>
                      ref.invalidate(userBookingsStreamProvider(userId)),
                  isSelectionMode: _isSelectionMode,
                  isSelected: _selectedIds.contains(booking.id),
                  onSelect: () => _toggleSelection(booking.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cancelBooking(String bookingId, String userId) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Batalkan Pesanan?',
      message: 'Apakah Anda yakin ingin membatalkan pesanan ini?',
      confirmText: 'Ya, Batalkan',
      isDestructive: true,
    );
    if (!confirm) return;

    try {
      final service = ref.read(bookingServiceProvider);
      await service.cancelBooking(bookingId);
      ref.invalidate(userBookingsStreamProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pesanan berhasil dibatalkan'),
          backgroundColor: AppColors.primary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}

// ── BOOKING CARD ──────────────────────────────────────────────────────────────
class _BookingCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Gunakan BookingStatus untuk semua mapping status → UI
    final displayStatus =
        (booking.isRescheduleRequested && booking.rescheduleStatus == 'pending')
            ? BookingStatus.menungguKonfirmasi.firestoreValue
            : booking.status;
    final status = BookingStatusParsing.fromString(displayStatus);
    final dateStr =
        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.isEmpty
        ? '-'
        : booking.timeSlots.length > 1
            ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]}'
            : booking.timeSlots.first;

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          onSelect?.call();
        } else {
          Navigator.pushNamed(context, '/booking-detail',
              arguments: booking.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID + Status Badge
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
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ),
                      Text('#${booking.bookingId}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  // Badge — pakai status.backgroundColor & status.badgeLabel
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.badgeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status.color),
                    ),
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
                  CachedImageWidget(
                    imageUrl: booking.fieldImageUrl,
                    width: 64,
                    height: 64,
                    borderRadius: 12,
                    errorWidget: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.stadium_outlined,
                            size: 28, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.fieldName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text('$dateStr • $timeStr',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary))),
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
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL BAYAR',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(booking.totalBayar),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ]),
                  const Spacer(),
                  ..._buildActions(context, ref, status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action buttons berdasarkan BookingStatus — tidak ada switch-case hardcode
  List<Widget> _buildActions(
      BuildContext context, WidgetRef ref, BookingStatus status) {
    switch (status) {
      case BookingStatus.menungguBayar:
        return [
          _actionBtn(Icons.payment, 'Bayar', AppColors.statusPending, () async {
            if (booking.paymentUrl != null) {
              final uri = Uri.parse(booking.paymentUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          }),
          const SizedBox(width: 8),
          _actionBtn(Icons.close, 'Batal', Colors.red.shade400, onCancel),
        ];
      case BookingStatus.menungguKonfirmasi:
        return [
          _actionBtn(Icons.close, 'Batal', Colors.red.shade400, onCancel),
        ];
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return [
          _actionBtn(Icons.qr_code_2, 'E-Ticket', AppColors.primary, () {
            Navigator.pushNamed(context, '/booking-detail',
                arguments: booking.id);
          }),
        ];
      case BookingStatus.selesai:
        if (booking.isReviewed) {
          return [
            _actionBtn(Icons.star, 'Sudah Diulas', Colors.grey, () {}),
          ];
        }
        return [
          _actionBtn(Icons.star_outline, 'Beri Ulasan', Colors.amber.shade700,
              () => _showReviewDialog(context, ref)),
        ];
      case BookingStatus.dibatalkan:
      case BookingStatus.ditolak:
      case BookingStatus.expired:
      case BookingStatus.unknown:
        return [];
    }
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;
    File? imageFile;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            title: const Center(
              child: Text('Beri Ulasan',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Bagaimana pengalaman Anda di ${booking.fieldName}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => rating = index + 1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: index < rating
                                      ? AppColors.star
                                      : Colors.transparent,
                                  size: 32,
                                ),
                                Icon(
                                  Icons.star_outline_rounded,
                                  color: index < rating
                                      ? Colors.black.withValues(alpha: 0.8)
                                      : Colors.grey.shade500,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan ulasan Anda (opsional)...',
                      hintStyle:
                          const TextStyle(fontSize: 14, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Upload Foto (Opsional)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        setState(() => imageFile = File(image.path));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: imageFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child:
                                      Image.file(imageFile!, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => imageFile = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]),
                                  child: const Icon(Icons.add_a_photo_outlined,
                                      size: 24, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                const Text('Ketuk untuk tambah foto',
                                    style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal',
                    style: TextStyle(
                        color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          String? imageUrl;
                          if (imageFile != null) {
                            imageUrl = await FirebaseStorageService.uploadImage(
                                imageFile!,
                                folder: 'reviews');
                          }

                          final service = ref.read(reviewServiceProvider);
                          await service.submitReview(
                            bookingId: booking.id,
                            fieldId: booking.fieldId,
                            userId: booking.userId,
                            userName: booking.userName,
                            rating: rating,
                            comment: commentController.text.trim(),
                            reviewImageUrl: imageUrl,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Terima kasih atas ulasan Anda!'),
                                  backgroundColor: AppColors.primary),
                            );
                            onRefresh();
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal: $e'),
                                  backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Mengunggah...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Text('Kirim Ulasan',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
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
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
