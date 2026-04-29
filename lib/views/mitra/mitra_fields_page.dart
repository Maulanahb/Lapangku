import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/mitra/field/providers/mitra_field_provider.dart';
import 'package:lapangku/features/mitra/field/models/mitra_field_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:lapangku/views/Mitra/widgets/mitra_field_form_sheet.dart';

class MitraFieldsPage extends ConsumerStatefulWidget {
  const MitraFieldsPage({super.key});

  @override
  ConsumerState<MitraFieldsPage> createState() => _MitraFieldsPageState();
}

class _MitraFieldsPageState extends ConsumerState<MitraFieldsPage> {

  void _toggleStatus(String fieldId, bool currentStatus, String fieldName) async {
    try {
      await ref.read(mitraFieldProvider.notifier).toggleFieldStatus(fieldId, currentStatus);
      if (mounted) {
        SnackbarHelper.showSuccess(
          context, 
          'Status $fieldName diubah menjadi ${!currentStatus ? "Aktif" : "Nonaktif"}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal mengubah status');
      }
    }
  }

  void _showAddEditBottomSheet({MitraFieldModel? field}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return MitraFieldFormSheet(field: field);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldState = ref.watch(mitraFieldProvider);
    final fieldsAsync = fieldState.fields;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Lapangan Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: () {
        if (fieldsAsync is AsyncLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A)));
        } else if (fieldsAsync is AsyncError) {
          return Center(child: Text('Gagal memuat: ${fieldsAsync.error}'));
        } else if (fieldsAsync is AsyncData) {
          final fields = fieldsAsync.value;
          if (fields == null || fields.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stadium_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Belum ada lapangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('Tambahkan lapangan pertama Anda untuk mulai disewa.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: const Color(0xFF1B6B3A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.sports_soccer, color: Color(0xFF1B6B3A), size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(field.namaLapangan, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Rp ${field.hargaPerJam} / jam', style: const TextStyle(color: Color(0xFF1B6B3A), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(field.isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(color: field.isActive ? Colors.green : Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          value: field.isActive,
                          onChanged: (v) => _toggleStatus(field.id, field.isActive, field.namaLapangan),
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF1B6B3A),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                          onPressed: () => _showAddEditBottomSheet(field: field),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox();
      }(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: const Color(0xFF1B6B3A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
