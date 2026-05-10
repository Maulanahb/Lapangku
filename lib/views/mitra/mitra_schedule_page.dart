import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/models/mitra/mitra_schedule_model.dart';
import 'package:lapangku/controllers/mitra/mitra_schedule_provider.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraSchedulePage extends ConsumerWidget {
  const MitraSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(mitraFieldProvider).fields;
    final scheduleState = ref.watch(mitraScheduleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Jadwal Operasional',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: fieldsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
        error: (e, _) =>
            Center(child: Text('Gagal memuat lapangan: $e')),
        data: (fields) {
          if (fields.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stadium_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada lapangan.\nTambahkan lapangan terlebih dahulu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Dropdown pilih lapangan
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: scheduleState.selectedFieldId,
                  decoration: InputDecoration(
                    labelText: 'Pilih Lapangan',
                    prefixIcon: const Icon(Icons.stadium_outlined,
                        color: Color(0xFF1B6B3A)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B6B3A)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  hint: const Text('-- Pilih lapangan --'),
                  items: fields
                      .map((f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.namaLapangan,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      ref
                          .read(mitraScheduleProvider.notifier)
                          .selectField(id);
                    }
                  },
                ),
              ),

              // Konten jadwal
              Expanded(
                child: scheduleState.selectedFieldId == null
                    ? const Center(
                        child: Text('Pilih lapangan untuk melihat jadwal.',
                            style: TextStyle(color: Colors.grey)))
                    : scheduleState.schedule.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF1B6B3A))),
                        error: (e, _) =>
                            Center(child: Text('Gagal memuat jadwal: $e')),
                        data: (schedules) => _ScheduleList(schedules: schedules),
                      ),
              ),

              // Tombol simpan
              if (scheduleState.selectedFieldId != null)
                _SaveButton(isSaving: scheduleState.isSaving),
            ],
          );
        },
      ),
    );
  }
}

// â”€â”€ Daftar jadwal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ScheduleList extends ConsumerWidget {
  final List<MitraScheduleModel> schedules;

  const _ScheduleList({required this.schedules});

  // Helper map untuk mengonversi dayOfWeek (int) menjadi nama hari (String)
  String _getNamaHari(int dayOfWeek) {
    const mapHari = {
      1: 'Senin', 2: 'Selasa', 3: 'Rabu',
      4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'
    };
    return mapHari[dayOfWeek] ?? 'Senin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final s = schedules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.isActive
                  ? const Color(0xFF1B6B3A).withValues(alpha: 0.2)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getNamaHari(s.dayOfWeek), // Menggunakan helper fungsi
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: s.isActive ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        s.isActive ? 'Buka' : 'Tutup',
                        style: TextStyle(
                            color: s.isActive
                                ? const Color(0xFF1B6B3A)
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: s.isActive,
                        onChanged: (val) {
                          ref
                              .read(mitraScheduleProvider.notifier)
                              .updateDaySchedule(index, isActive: val);
                        },
                        activeTrackColor: const Color(0xFF1B6B3A),
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
              if (s.isActive) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Jam Buka',
                        time: s.jamBuka,
                        onTap: () async {
                          final picked = await _pickTime(
                              context, s.jamBuka);
                          if (picked != null) {
                            ref
                                .read(mitraScheduleProvider.notifier)
                                .updateDaySchedule(index, jamBuka: picked);
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('â€”',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 18)),
                    ),
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Jam Tutup',
                        time: s.jamTutup,
                        onTap: () async {
                          final picked = await _pickTime(
                              context, s.jamTutup);
                          if (picked != null) {
                            ref
                                .read(mitraScheduleProvider.notifier)
                                .updateDaySchedule(index, jamTutup: picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickTime(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }
}

// â”€â”€ Time picker button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1B6B3A).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Color(0xFF1B6B3A)),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B6B3A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Save button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SaveButton extends ConsumerWidget {
  final bool isSaving;

  const _SaveButton({required this.isSaving});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6B3A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: isSaving
              ? null
              : () async {
                  try {
                    await ref
                        .read(mitraScheduleProvider.notifier)
                        .saveSchedule();
                    if (context.mounted) {
                      SnackbarHelper.showSuccess(
                          context, 'Jadwal berhasil disimpan');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarHelper.showError(
                          context, 'Gagal menyimpan jadwal: $e');
                    }
                  }
                },
          child: isSaving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Simpan Jadwal',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
        ),
      ),
    );
  }
}
