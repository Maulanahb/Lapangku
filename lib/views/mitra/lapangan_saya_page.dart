import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'jadwal_ketersediaan_page.dart';

class LapanganSayaPage extends ConsumerWidget {
  const LapanganSayaPage({super.key});

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    dynamic field,
    List<BookingModel> bookings,
  ) async {
    final isActive = field.isActive;
    
    if (isActive) {
      // Trying to deactivate (Active -> Inactive)
      // Check for active bookings on this field
      final activeBookings = bookings.where((b) =>
          b.fieldId == field.id &&
          (b.status == 'menunggu_bayar' ||
              b.status == 'menunggu_konfirmasi' ||
              b.status == 'dikonfirmasi' ||
              b.status == 'ongoing')).toList();

      if (activeBookings.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Gagal Menonaktifkan'),
            content: Text(
              'Lapangan "${field.namaLapangan}" tidak dapat dinonaktifkan karena memiliki ${activeBookings.length} booking aktif yang belum selesai.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Toggle status
    try {
      await ref.read(mitraFieldProvider.notifier).toggleFieldStatus(field.id, field.isActive);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Lapangan "${field.namaLapangan}" berhasil disembunyikan'
                  : 'Lapangan "${field.namaLapangan}" berhasil diaktifkan',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Koneksi Gagal'),
            content: const Text('Gagal memperbarui status lapangan karena masalah koneksi.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleToggle(context, ref, field, bookings);
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final fieldState = ref.watch(mitraFieldProvider);
    final fieldsAsync = fieldState.fields;
    final bookingsAsync = ref.watch(mitraBookingsStreamProvider(uid));

    return fieldsAsync.when(
      data: (fields) {
        final activeCount = fields.where((f) => f.isActive).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F5A38)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lapangan Saya',
                  style: TextStyle(
                    color: Color(0xFF1E3020),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Kelola status lapangan',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5A38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$activeCount Aktif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          body: fields.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.stadium_outlined,
                  title: 'Belum Ada Lapangan',
                  subtitle: 'Tambahkan lapangan pertama Anda di menu pengelolaan.',
                )
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    // Hero Card (Green Container)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B6E4F), Color(0xFF074F35)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Stadium overlay graphic on the right
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.stadium_rounded,
                                    size: 68,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$activeCount Lapangan\nSedang Aktif',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Customer dapat melihat dan memesan lapangan aktif.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // List of Fields
                    Expanded(
                      child: ListView.separated(
                        itemCount: fields.length,
                        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final field = fields[index];
                          final isActive = field.isActive;
                          final photoUrl = field.photoUrls.isNotEmpty ? field.photoUrls.first : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JadwalKetersediaanPage(lapangan: field),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image with badge
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                      child: CachedImageWidget(
                                        imageUrl: photoUrl,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Badge overlay top-right
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isActive ? Colors.green : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isActive ? 'AKTIF' : 'NONAKTIF',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Details
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        field.namaLapangan,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF1E3020),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        field.tipeLapangan,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            isActive ? Icons.check_circle_outline : Icons.visibility_off_outlined,
                                            color: isActive ? Colors.green : Colors.grey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              isActive
                                                  ? 'Sedang menerima booking customer'
                                                  : 'Tidak tampil di pencarian customer',
                                              style: TextStyle(
                                                color: isActive ? Colors.green : Colors.grey,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            isActive ? 'Booking aktif' : 'Disembunyikan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? const Color(0xFF1E3020) : Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Switch(
                                            value: isActive,
                                            onChanged: (val) {
                                              final bookings = bookingsAsync.value ?? [];
                                              _handleToggle(context, ref, field, bookings);
                                            },
                                            activeColor: Colors.white,
                                            activeTrackColor: const Color(0xFF0B6E4F),
                                            inactiveThumbColor: Colors.white,
                                            inactiveTrackColor: Colors.grey.shade300,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      ),
                    ),
                    // Info Footer Box
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF2B5C8F),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hanya lapangan aktif yang dapat menerima booking',
                                style: TextStyle(
                                  color: Color(0xFF2B5C8F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Text('Terjadi kesalahan: $err'),
        ),
      ),
    );
  }
}
