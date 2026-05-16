import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/controllers/mitra/mitra_booking_provider.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraOfflineBookingPage extends ConsumerStatefulWidget {
  const MitraOfflineBookingPage({super.key});

  @override
  ConsumerState<MitraOfflineBookingPage> createState() =>
      _MitraOfflineBookingPageState();
}

class _MitraOfflineBookingPageState
    extends ConsumerState<MitraOfflineBookingPage> {
  MitraFieldModel? _selectedField;
  DateTime? _selectedDate;
  final List<String> _selectedSlots = [];
  final _namaCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  bool _isLoading = false;
  List<String> _bookedSlots = [];
  bool _loadingSlots = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  /// Generate time slots berdasarkan jam buka & tutup lapangan
  List<String> _generateTimeSlots() {
    if (_selectedField == null) return [];
    final open = int.tryParse(_selectedField!.jamBuka.split(':')[0]) ?? 6;
    final close = int.tryParse(_selectedField!.jamTutup.split(':')[0]) ?? 22;
    return List.generate(
      close - open,
      (i) =>
          '${(open + i).toString().padLeft(2, '0')}:00 - ${(open + i + 1).toString().padLeft(2, '0')}:00',
    );
  }

  /// Load booked slots dari Firestore untuk tanggal yang dipilih
  Future<void> _loadBookedSlots() async {
    if (_selectedField == null || _selectedDate == null) return;
    setState(() => _loadingSlots = true);
    try {
      final slots = await BookingService().getBookedSlots(
        fieldId: _selectedField!.id,
        date: _selectedDate!,
      );
      setState(() {
        _bookedSlots = slots;
        // Hapus slot yang sudah terisi dari pilihan
        _selectedSlots.removeWhere((s) => _bookedSlots.contains(s));
      });
    } catch (_) {}
    setState(() => _loadingSlots = false);
  }

  Future<void> _submit() async {
    if (_selectedField == null) {
      SnackbarHelper.showError(context, 'Pilih lapangan terlebih dahulu');
      return;
    }
    if (_selectedDate == null) {
      SnackbarHelper.showError(context, 'Pilih tanggal terlebih dahulu');
      return;
    }
    if (_selectedSlots.isEmpty) {
      SnackbarHelper.showError(context, 'Pilih minimal 1 slot waktu');
      return;
    }
    if (_namaCtrl.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Masukkan nama penyewa');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final mitraId = FirebaseAuth.instance.currentUser?.uid ?? '';
      // Sort slots agar berurutan
      _selectedSlots.sort();
      await ref.read(MitraBookingActionsProvider.notifier).createOfflineBooking(
            field: _selectedField!,
            mitraId: mitraId,
            date: _selectedDate!,
            timeSlots: _selectedSlots,
            namaPenyewa: _namaCtrl.text.trim(),
            catatan: _catatanCtrl.text.trim(),
          );
      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Booking offline berhasil ditambahkan!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(MitraFieldListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text('Tambah Booking Offline',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Banner ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gunakan fitur ini untuk memblokir slot jadwal yang sudah dipesan langsung (telepon, WhatsApp, datang langsung).',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 1. Pilih Lapangan ──
            _sectionTitle('1. Pilih Lapangan', Icons.stadium_outlined),
            const SizedBox(height: 8),
            fieldsAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text('Error: $e'),
              data: (fields) {
                if (fields.isEmpty) {
                  return const Text('Belum ada lapangan. Tambahkan lapangan terlebih dahulu.');
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MitraFieldModel>(
                      isExpanded: true,
                      hint: const Text('Pilih Lapangan'),
                      value: _selectedField,
                      items: fields
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.namaVenue.isNotEmpty
                                      ? '${f.namaVenue} - ${f.namaLapangan}'
                                      : f.namaLapangan,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedField = v;
                          _selectedSlots.clear();
                          _bookedSlots.clear();
                        });
                        if (_selectedDate != null) _loadBookedSlots();
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── 2. Pilih Tanggal ──
            _sectionTitle('2. Pilih Tanggal', Icons.calendar_today),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _selectedSlots.clear();
                  });
                  _loadBookedSlots();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? DateFormat('EEEE, dd MMM yyyy', 'id_ID')
                              .format(_selectedDate!)
                          : 'Pilih Tanggal',
                      style: TextStyle(
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey),
                    ),
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 3. Pilih Slot Waktu ──
            _sectionTitle('3. Pilih Jam', Icons.access_time),
            const SizedBox(height: 8),
            if (_selectedField == null || _selectedDate == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Pilih lapangan & tanggal terlebih dahulu',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else if (_loadingSlots)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
            else
              _buildTimeSlotGrid(),
            const SizedBox(height: 24),

            // ── 4. Nama Penyewa ──
            _sectionTitle('4. Nama Penyewa', Icons.person_outline),
            const SizedBox(height: 8),
            TextField(
              controller: _namaCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Budi (WA)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 24),

            // ── 5. Catatan (Opsional) ──
            _sectionTitle('5. Catatan (Opsional)', Icons.note_alt_outlined),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Bayar cash di tempat',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Booking Offline',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }

  Widget _buildTimeSlotGrid() {
    final allSlots = _generateTimeSlots();
    if (allSlots.isEmpty) {
      return const Text('Tidak ada slot tersedia untuk lapangan ini.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allSlots.map((slot) {
        final isBooked = _bookedSlots.contains(slot);
        final isSelected = _selectedSlots.contains(slot);

        return GestureDetector(
          onTap: isBooked
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedSlots.remove(slot);
                    } else {
                      _selectedSlots.add(slot);
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isBooked
                  ? Colors.red.shade50
                  : isSelected
                      ? AppColors.primary
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isBooked
                    ? Colors.red.shade300
                    : isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isBooked
                    ? Colors.red.shade400
                    : isSelected
                        ? Colors.white
                        : Colors.black87,
                decoration:
                    isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
