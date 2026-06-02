import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

class JadwalKetersediaanPage extends StatefulWidget {
  final MitraFieldModel lapangan;

  const JadwalKetersediaanPage({
    super.key,
    required this.lapangan,
  });

  @override
  State<JadwalKetersediaanPage> createState() => _JadwalKetersediaanPageState();
}

class _JadwalKetersediaanPageState extends State<JadwalKetersediaanPage> {
  late List<DateTime> _dates;
  late DateTime _selectedDate;

  // Local state to keep track of modifications before saving
  // Map<Jam, Status>
  final Map<String, String> _modifiedSlots = {};

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (index) => now.add(Duration(days: index)));
    _selectedDate = _dates.first;
  }

  String _formatDay(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return '';
    }
  }

  String _formatMonth(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[date.month];
  }

  List<String> _generateTimeSlots() {
    int startHour = 7;
    int endHour = 23;

    try {
      if (widget.lapangan.jamBuka.isNotEmpty) {
        startHour = int.parse(widget.lapangan.jamBuka.split(':')[0]);
      }
      if (widget.lapangan.jamTutup.isNotEmpty) {
        endHour = int.parse(widget.lapangan.jamTutup.split(':')[0]);
      }
    } catch (e) {
      // Default to 07:00 - 23:00 if parsing fails
    }

    List<String> slots = [];
    for (int i = startHour; i <= endHour; i++) {
      slots.add('${i.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  Stream<Map<String, Map<String, dynamic>>> _getCombinedJadwalStream() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final startOfDayDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDayDate = startOfDayDate.add(const Duration(days: 1));

    // Stream 1: jadwal (untuk manual closure/status dari Mitra)
    final streamJadwal = FirestoreService.instance
        .collection('jadwal')
        .where('lapangan_id', isEqualTo: widget.lapangan.id)
        .where('tanggal', isEqualTo: dateStr)
        .snapshots();

    // Stream 2: bookings (booking aktif dari Customer)
    final streamBookings = FirestoreService.instance
        .collection('bookings')
        .where('fieldId', isEqualTo: widget.lapangan.id)
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayDate))
        .where('tanggal', isLessThan: Timestamp.fromDate(endOfDayDate))
        .snapshots();

    final controller = StreamController<Map<String, Map<String, dynamic>>>();
    StreamSubscription? subJadwal;
    StreamSubscription? subBookings;
    QuerySnapshot? lastJadwal;
    QuerySnapshot? lastBookings;

    void emitCombined() {
      if (controller.isClosed) return;
      final combined = <String, Map<String, dynamic>>{};

      // 1. Proses data dari koleksi 'jadwal'
      if (lastJadwal != null) {
        for (var doc in lastJadwal!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final jam = data['jam'] as String?;
          if (jam != null) {
            combined[jam] = {
              'status': data['status'] ?? 'tersedia',
              'nama_customer': data['nama_customer'] ?? '',
              'waktu_booking': data['waktu_booking'] ?? '',
            };
          }
        }
      }

      // 2. Proses data booking riil dari koleksi 'bookings'
      if (lastBookings != null) {
        for (var doc in lastBookings!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final status = data['status'] as String?;
          
          // Skip booking yang dibatalkan, expired, atau ditolak
          if (status == 'dibatalkan' || status == 'expired' || status == 'ditolak') {
            continue;
          }

          final timeSlots = data['timeSlots'] as List<dynamic>?;
          final userName = data['userName'] as String? ?? 'Customer';
          final createdAtRaw = data['createdAt'];
          String waktuBookingStr = '';
          
          if (createdAtRaw is Timestamp) {
            waktuBookingStr = DateFormat('HH:mm').format(createdAtRaw.toDate());
          } else if (createdAtRaw is String) {
            final dt = DateTime.tryParse(createdAtRaw);
            if (dt != null) {
              waktuBookingStr = DateFormat('HH:mm').format(dt);
            }
          }

          if (timeSlots != null) {
            for (var slot in timeSlots) {
              if (slot is String) {
                // Map "08:00 - 09:00" -> "08:00"
                final jamMulai = slot.split(' - ').first.trim();
                combined[jamMulai] = {
                  'status': 'dibooking',
                  'nama_customer': userName,
                  'waktu_booking': waktuBookingStr,
                };
              }
            }
          } else {
            // Fallback jamMulai
            final jamMulai = data['jamMulai'] as String?;
            if (jamMulai != null && jamMulai.isNotEmpty) {
              combined[jamMulai] = {
                'status': 'dibooking',
                'nama_customer': userName,
                'waktu_booking': waktuBookingStr,
              };
            }
          }
        }
      }

      controller.add(combined);
    }

    subJadwal = streamJadwal.listen(
      (snap) {
        lastJadwal = snap;
        emitCombined();
      },
      onError: (err) => controller.addError(err),
    );

    subBookings = streamBookings.listen(
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

  Future<void> _simpanPerubahan() async {
    if (_modifiedSlots.isEmpty) return;

    LoadingOverlay.show(context, message: 'Menyimpan perubahan...');

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final batch = FirestoreService.instance.batch();

      for (var entry in _modifiedSlots.entries) {
        final jam = entry.key;
        final status = entry.value;

        // Query if document exists
        final querySnapshot = await FirestoreService.instance
            .collection('jadwal')
            .where('lapangan_id', isEqualTo: widget.lapangan.id)
            .where('tanggal', isEqualTo: dateStr)
            .where('jam', isEqualTo: jam)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Update existing
          batch.update(querySnapshot.docs.first.reference, {'status': status});
        } else {
          // Create new
          final newDoc = FirestoreService.instance.collection('jadwal').doc();
          batch.set(newDoc, {
            'lapangan_id': widget.lapangan.id,
            'tanggal': dateStr,
            'jam': jam,
            'status': status,
            'nama_customer': '',
            'waktu_booking': '',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      _modifiedSlots.clear();
      
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perubahan berhasil disimpan 😊'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perubahan: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleSlotStatus(String jam, String currentStatus) {
    if (currentStatus == 'dibooking') {
      // Cannot toggle a booked slot directly
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot yang sudah dibooking tidak dapat diubah dari sini.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String newStatus = currentStatus == 'tersedia' ? 'ditutup' : 'tersedia';
    setState(() {
      _modifiedSlots[jam] = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jadwal & Ketersediaan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubheader(),
          _buildInfoLapangan(),
          const SizedBox(height: 16),
          _buildPilihanTanggal(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: _getCombinedJadwalStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                final firestoreData = snapshot.data ?? {};
                
                final slots = _generateTimeSlots();

                if (slots.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Tidak ada jam operasional',
                    subtitle: 'Periksa kembali jam buka dan jam tutup lapangan.',
                    icon: Icons.access_time,
                  );
                }

                int availableCount = 0;
                int bookedCount = 0;
                int closedCount = 0;

                // Calculate stats
                for (var jam in slots) {
                  String status = 'tersedia';
                  
                  if (_modifiedSlots.containsKey(jam)) {
                    status = _modifiedSlots[jam]!;
                  } else if (firestoreData.containsKey(jam)) {
                    status = firestoreData[jam]!['status'] ?? 'tersedia';
                  }

                  if (status == 'tersedia') {
                    availableCount++;
                  } else if (status == 'dibooking') {
                    bookedCount++;
                  } else if (status == 'ditutup') {
                    closedCount++;
                  }
                }

                return Column(
                  children: [
                    _buildRingkasanHariIni(availableCount, bookedCount, closedCount),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100), // padding for FAB
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final jam = slots[index];
                          
                          // Determine status
                          String status = 'tersedia';
                          Map<String, dynamic>? data;
                          
                          if (_modifiedSlots.containsKey(jam)) {
                            status = _modifiedSlots[jam]!;
                            data = firestoreData[jam];
                          } else if (firestoreData.containsKey(jam)) {
                            data = firestoreData[jam];
                            status = data?['status'] ?? 'tersedia';
                          }

                          return _buildSlotCard(jam, status, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _modifiedSlots.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: _simpanPerubahan,
                backgroundColor: AppColors.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                label: const Text(
                  'Simpan Perubahan 😊',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSubheader() {
    return Container(
      color: AppColors.primary,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: const Text(
        'Kelola slot booking harian',
        style: TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInfoLapangan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lapangan.namaLapangan,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lapangan.tipeLapangan,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sedang aktif menerima booking',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AKTIF',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilihanTanggal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Hari Ini',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _modifiedSlots.clear(); // Reset unsaved changes on date change
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySelected : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderLight,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day} ${_formatMonth(date)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textHeading,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDay(date),
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasanHariIni(int availableCount, int bookedCount, int closedCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN HARI INI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$availableCount Slot Tersedia',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$bookedCount slot sudah dibooking • $closedCount slot ditutup',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Jam operasional ${widget.lapangan.jamBuka} — ${widget.lapangan.jamTutup}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSlotCard(String jam, String status, Map<String, dynamic>? data) {
    bool isTersedia = status == 'tersedia';
    bool isDibooking = status == 'dibooking';
    bool isDitutup = status == 'ditutup';

    int hour = int.parse(jam.split(':')[0]);
    String amPm = hour < 12 ? 'Pagi' : (hour < 18 ? 'Sore' : 'Malam');

    return GestureDetector(
      onTap: () => _toggleSlotStatus(jam, status),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTersedia ? AppColors.primaryBorder : Colors.transparent,
            width: isTersedia ? 1 : 0,
          ),
          boxShadow: isDitutup ? null : const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: isDitutup ? 0.6 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kiri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$jam $amPm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDitutup ? AppColors.textSecondary : AppColors.textHeading,
                        decoration: isDitutup ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isTersedia)
                      const Text(
                        'Tersedia',
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      )
                    else if (isDibooking)
                      Row(
                        children: [
                          const Text(
                            'Sudah Dibooking',
                            style: TextStyle(fontSize: 12, color: AppColors.statusPending),
                          ),
                          const SizedBox(width: 8),
                          if (data != null && data['nama_customer'] != null && data['nama_customer'].toString().isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      data['nama_customer'].toString().substring(0, 1).toUpperCase(),
                                      style: const TextStyle(fontSize: 10, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      data['nama_customer'],
                                      style: const TextStyle(fontSize: 12, color: AppColors.textHeading),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    else if (isDitutup)
                      const Text(
                        'Tidak menerima booking',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              
              // Kanan
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isTersedia) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Slot siap menerima booking',
                        style: TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                  ] else if (isDibooking) ...[
                    if (data != null && data['waktu_booking'] != null && data['waktu_booking'].toString().isNotEmpty)
                      Text(
                        data['waktu_booking'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 8),
                    const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
                  ] else if (isDitutup) ...[
                    const Icon(Icons.lock_outline, size: 24, color: AppColors.textSecondary),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
