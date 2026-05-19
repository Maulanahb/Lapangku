// lib/views/Mitra/manage_fields_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/views/mitra/add_field_page.dart';
import 'package:lapangku/views/mitra/edit_field_page.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';

class ManageFieldsPage extends ConsumerStatefulWidget {
  const ManageFieldsPage({super.key});

  @override
  ConsumerState<ManageFieldsPage> createState() => _ManageFieldsPageState();
}

class _ManageFieldsPageState extends ConsumerState<ManageFieldsPage> {
  final Color _primaryGreen = const Color(0xFF0F5A3C);
  final Color _textGrey = const Color(0xFF6B7280);

  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final fieldState = ref.watch(mitraFieldProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: fieldState.fields.when(
                data: (fields) {
                  if (fields.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(mitraFieldProvider.notifier).loadFields(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: fields.length,
                      itemBuilder: (context, index) {
                        final field = fields[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildFieldCard(field),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Gagal memuat data: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Belum ada lapangan',
              style: TextStyle(
                  color: _textGrey, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tekan tombol + Tambah untuk memulai',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Lapangan Saya',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _primaryGreen,
                  letterSpacing: -0.5)),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFieldPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: const Row(children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text('Tambah',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(MitraFieldModel field) {
    bool isActive = field.isActive;
    String imageUrl = field.photoUrls.isNotEmpty
        ? field.photoUrls[0]
        : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=1000&auto=format&fit=crop';

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported,
                          color: Colors.grey[400])))),
          Positioned(
              top: 16,
              right: 16,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF86EFAC).withValues(alpha: 0.9)
                          : const Color(0xFFE5E7EB).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFF166534)
                              : const Color(0xFF4B5563),
                          fontWeight: FontWeight.w800,
                          fontSize: 12)))),
        ]),
        Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(field.namaLapangan,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2)),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await ConfirmationDialog.show(
                          context: context,
                          title: 'Hapus Lapangan',
                          message:
                              'Apakah Anda yakin ingin menghapus lapangan ini?',
                          confirmText: 'Hapus',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          await ref
                              .read(mitraFieldProvider.notifier)
                              .deleteField(field.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Lapangan berhasil dihapus')),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Hapus Lapangan',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEBF5FF),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(field.jenisLapangan,
                        style: const TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w800))),
                ...field.fasilitas.take(2).map((tag) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(tag,
                        style: TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)))),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 24),
                  const SizedBox(width: 4),
                  Text(field.avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(' (${field.totalReviews} ulasan)',
                      style: TextStyle(
                          color: _textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ]),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: _currencyFormat.format(field.hargaPerJam),
                      style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  TextSpan(
                      text: '/jam',
                      style: TextStyle(
                          color: _textGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ])),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 18, color: _textGrey),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(field.alamat,
                        style: TextStyle(
                            color: _textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis)),
              ]),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(
                      height: 1, color: Color(0xFFF3F4F6), thickness: 1.5)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Status Lapangan',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                      isActive
                          ? 'Aktif — Menerima Pesanan'
                          : 'Nonaktif — Lapangan Ditutup',
                      style: TextStyle(
                          color: isActive ? const Color(0xFF059669) : _textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
                Switch(
                    value: isActive,
                    onChanged: (val) {
                      ref
                          .read(mitraFieldProvider.notifier)
                          .toggleFieldStatus(field.id, isActive);
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF166534),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFD1D5DB)),
              ]),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditFieldPage(field: field),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: Colors.grey[200]!, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(
                                isActive
                                    ? Icons.calendar_today_rounded
                                    : Icons.calendar_month_outlined,
                                size: 18),
                            label: Text(isActive ? 'Lihat Jadwal' : 'Jadwal'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? const Color(0xFFEBF5FF)
                                    : Colors.white,
                                foregroundColor: isActive
                                    ? const Color(0xFF1E40AF)
                                    : Colors.grey[400],
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: !isActive
                                    ? BorderSide(color: Colors.grey[100]!)
                                    : BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))))),
                  ])),
            ])),
      ]),
    );
  }
}
