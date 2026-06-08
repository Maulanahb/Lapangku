import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

class JadwalLapanganPage extends StatefulWidget {
  final MitraFieldModel lapangan;

  const JadwalLapanganPage({
    super.key,
    required this.lapangan,
  });

  @override
  State<JadwalLapanganPage> createState() => _JadwalLapanganPageState();
}

class _JadwalLapanganPageState extends State<JadwalLapanganPage> {
  late List<DateTime> _dates;
  late DateTime _selectedDate;

  final Color _primaryGreen = const Color(0xFF0F5A3C);
  final Color _bgLightGreen = const Color(0xFFE8F5EF);

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    final now = DateTime.now();
    // Generate tanggal untuk 14 hari ke depan
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(14, (index) {
      final date = now.add(Duration(days: index));
      return DateTime(date.year, date.month, date.day);
    });
  }

  String _formatDay(DateTime date) {
    return DateFormat('EEE', 'id').format(date);
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMM', 'id').format(date);
  }

  // Fungsi untuk mengecek apakah slot jam sudah lewat dari waktu saat ini
  bool _isTimeSlotPast(String jamStr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedDate.isBefore(today)) {
      return true;
    }
    if (_selectedDate.isAfter(today)) {
      return false;
    }

    try {
      final parts = jamStr.split(':');
      final slotHour = int.parse(parts[0]);
      final slotMinute = parts.length > 1 ? int.parse(parts[1]) : 0;

      final slotTime =
          DateTime(now.year, now.month, now.day, slotHour, slotMinute);
      return now.isAfter(slotTime);
    } catch (e) {
      return false;
    }
  }

  List<String> _generateTimeSlots() {
    final List<String> slots = [];
    try {
      final int startHour = int.parse(widget.lapangan.jamBuka.split(':')[0]);
      final int endHour = int.parse(widget.lapangan.jamTutup.split(':')[0]);

      for (int i = startHour; i < endHour; i++) {
        slots.add('${i.toString().padLeft(2, '0')}:00');
      }
    } catch (e) {
      // Fallback jika format jam salah
      for (int i = 8; i < 22; i++) {
        slots.add('${i.toString().padLeft(2, '0')}:00');
      }
    }
    return slots;
  }

  Stream<Map<String, Map<String, dynamic>>> _getCombinedJadwalStream() {
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Set rentang waktu Timestamp hari ini dari jam 00:00 sampai 23:59
    final DateTime startOfDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final DateTime endOfDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    // Stream 1: Jadwal manual penutupan slot (koleksi schedules menggunakan fieldId)
    final Stream<QuerySnapshot> jadwalStream = FirestoreService.instance
        .collection('schedules')
        .where('fieldId', isEqualTo: widget.lapangan.id)
        .where('tanggal', isEqualTo: dateStr)
        .snapshots();

    // Stream 2: Booking riil customer (Menggunakan field 'tanggal' bertipe Timestamp & status Lapangku)
    final Stream<QuerySnapshot> bookingStream = FirestoreService.instance
        .collection('bookings')
        .where('fieldId', isEqualTo: widget.lapangan.id)
        .where('tanggal',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots();

    final controller = StreamController<Map<String, Map<String, dynamic>>>();
    StreamSubscription? subJadwal;
    StreamSubscription? subBookings;
    QuerySnapshot? lastJadwal;
    QuerySnapshot? lastBookings;

    void emitCombined() {
      if (controller.isClosed) return;
      final combined = <String, Map<String, dynamic>>{};

      // 1. Masukkan status penonaktifan dari mitra
      if (lastJadwal != null) {
        for (var doc in lastJadwal!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final jam = data['jam'] as String?;
            if (jam != null) {
              combined[jam] = {
                'status': data['status'] ?? 'tersedia',
                'nama_customer': '',
              };
            }
          }
        }
      }

      // 2. Timpa dengan data booking riil dari customer
      if (lastBookings != null) {
        for (var doc in lastBookings!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final String bookingStatus = data['status'] ?? '';
            
            if (!['menunggu_bayar', 'menunggu_konfirmasi', 'dikonfirmasi'].contains(bookingStatus)) {
              continue;
            }

            final List<dynamic> timeSlots = data['timeSlots'] ?? [];
            final String customerName =
                data['userName'] ?? data['customerName'] ?? 'Customer';

            for (var slot in timeSlots) {
              if (slot is String && slot.contains(' - ')) {
                final String jamMulai = slot.split(' - ')[0].trim();
                combined[jamMulai] = {
                  'status': 'dibooking',
                  'nama_customer': customerName,
                };
              }
            }
          }
        }
      }

      controller.add(combined);
    }

    subJadwal = jadwalStream.listen(
      (snap) {
        lastJadwal = snap;
        emitCombined();
      },
      onError: (err) => controller.addError(err),
    );

    subBookings = bookingStream.listen(
      (snap) {
        lastBookings = snap;
        emitCombined();
      },
      onError: (err) => controller.addError(err),
    );

    controller.onCancel = () {
      subJadwal?.cancel();
      subBookings?.cancel();
    };

    return controller.stream;
  }



  Future<void> _updateSlotStatus(String jam, String newStatus) async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    LoadingOverlay.show(context, message: 'Mengubah status slot...');

    try {
      // Pastikan query mencari berdasarkan 'fieldId' secara konsisten
      final querySnapshot = await FirestoreService.instance
          .collection('schedules')
          .where('fieldId', isEqualTo: widget.lapangan.id)
          .where('tanggal', isEqualTo: dateStr)
          .where('jam', isEqualTo: jam)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'status': newStatus,
          'mitraId': widget.lapangan.mitraId,
        });
      } else {
        // Simpan data baru dengan fieldId (bukan lapangan_id) agar terbaca oleh Stream
        await FirestoreService.instance.collection('schedules').add({
          'fieldId': widget.lapangan.id,
          'mitraId': widget.lapangan.mitraId,
          'tanggal': dateStr,
          'jam': jam,
          'status': newStatus,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        LoadingOverlay.dismiss(context);
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(String jam, String currentStatus) {
    if (currentStatus == 'dibooking') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot yang sudah dibooking tidak dapat diubah.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isTimeSlotPast(jam)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot jam sudah lewat dan otomatis dikunci.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool isAktif = currentStatus == 'tersedia';
    final String actionText = isAktif ? 'Nonaktifkan' : 'Aktifkan';
    final String newStatus = isAktif ? 'ditutup' : 'tersedia';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('$actionText Slot?'),
          content: Text(
              'Apakah Anda yakin ingin $actionText slot $jam pada tanggal ${DateFormat('dd MMM yyyy').format(_selectedDate)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateSlotStatus(jam, newStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAktif ? Colors.red : _primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
                  Text(actionText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jadwal & Ketersediaan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<Map<String, Map<String, dynamic>>>(
        stream: _getCombinedJadwalStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final firestoreData = snapshot.data ?? {};
          final slots = _generateTimeSlots();

          int availableCount = 0;
          int bookedCount = 0;

          for (var jam in slots) {
            String status = firestoreData[jam]?['status'] ?? 'tersedia';
            if (_isTimeSlotPast(jam)) {
              // Jika jam sudah lewat, tidak dihitung sebagai slot aktif yang tersedia
              if (status == 'dibooking') bookedCount++;
            } else {
              if (status == 'tersedia') availableCount++;
              if (status == 'dibooking') bookedCount++;
            }
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(availableCount, bookedCount),
                      const SizedBox(height: 24),
                      _buildPilihanTanggal(),
                      const SizedBox(height: 20),
                      _buildSlotGrid(slots, firestoreData),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(int availableCount, int bookedCount) {
    String imageUrl = widget.lapangan.photoUrls.isNotEmpty
        ? widget.lapangan.photoUrls[0]
        : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=1000&auto=format&fit=crop';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.lapangan.namaLapangan,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _bgLightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Aktif',
                            style: TextStyle(
                              color: _primaryGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.lapangan.alamat,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                  'Jam Operasional ${widget.lapangan.jamBuka}-${widget.lapangan.jamTutup}',
                  const Color(0xFFEFF6FF),
                  const Color(0xFF1E3A8A)),
              _buildChip('$availableCount Slot Sisa', const Color(0xFFBBF7D0),
                  const Color(0xFF166534)),
              _buildChip('$bookedCount Dipesan', const Color(0xFFFCE7F3),
                  const Color(0xFF9D174D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPilihanTanggal() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? _primaryGreen : Colors.white,
                border: Border.all(
                  color: isSelected ? _primaryGreen : Colors.grey[300]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDay(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    _formatMonth(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid(
      List<String> slots, Map<String, Map<String, dynamic>> firestoreData) {
    if (slots.isEmpty) {
      return const EmptyStateWidget(
        title: 'Tidak ada jam operasional',
        subtitle: 'Periksa kembali jam buka dan jam tutup lapangan.',
        icon: Icons.access_time,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final jam = slots[index];
          final endJam =
              '${(int.parse(jam.split(':')[0]) + 1).toString().padLeft(2, '0')}:00';
          final jamRange = '$jam - $endJam';

          final data = firestoreData[jam];
          String status = data?['status'] ?? 'tersedia';
          final customerName = data?['nama_customer'] ?? '';

          // Jika jam sudah terlewati, paksa statusnya menjadi 'lewat' (kecuali sudah sukses dibooking)
          if (status != 'dibooking' && _isTimeSlotPast(jam)) {
            status = 'lewat';
          }

          return _buildSlotCard(jam, jamRange, status, customerName);
        },
      ),
    );
  }

  Widget _buildSlotCard(
      String jam, String jamRange, String status, String customerName) {
    final bool isTersedia = status == 'tersedia';
    final bool isDibooking = status == 'dibooking';
    final bool isDitutup = status == 'ditutup';
    final bool isLewat = status == 'lewat';

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Widget content;

    if (isLewat) {
      bgColor = const Color(0xFFF9FAFB);
      borderColor = const Color(0xFFE5E7EB);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(jamRange,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Sudah Lewat',
              style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      );
    } else if (isTersedia) {
      borderColor = _primaryGreen.withOpacity(0.3);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(jamRange,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Tersedia',
              style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      );
    } else if (isDitutup) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5).withOpacity(0.5);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 4),
              Text(jamRange,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _primaryGreen, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Aktifkan',
              style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    } else if (isDibooking) {
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF86EFAC);
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customerName.isNotEmpty ? customerName : 'Customer',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Color(0xFF166534)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(jamRange,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Color(0xFF15803D))),
          const SizedBox(height: 2),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Detail ',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534))),
              Icon(Icons.arrow_forward, size: 10, color: Color(0xFF166534)),
            ],
          )
        ],
      );
    } else {
      content = const SizedBox();
    }

    return GestureDetector(
      onTap: () {
        if (isLewat) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Slot waktu ini sudah lewat.'),
                duration: Duration(seconds: 1)),
          );
        } else if (isDibooking) {
          // ════════ UBAH DI SINI ════════
          // Dikosongkan atau beri info pembatalan jika diperlukan.
          // Karena tidak memanggil _showConfirmationDialog, jamnya otomatis tidak bisa dipencet/diubah statusnya lagi.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Jadwal telah terisi oleh booking aktif customer.'),
                duration: Duration(seconds: 1)),
          );
          // ══════════════════════════════
        } else {
          _showConfirmationDialog(jam, status);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isDibooking ? 12 : 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}
