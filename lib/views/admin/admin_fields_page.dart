import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';

class AdminFieldsPage extends ConsumerStatefulWidget {
  const AdminFieldsPage({super.key});

  @override
  ConsumerState<AdminFieldsPage> createState() => _AdminFieldsPageState();
}

class _AdminFieldsPageState extends ConsumerState<AdminFieldsPage> {
  static const _primary = Color(0xFF1B6B3A);
  String _searchQuery = '';
  String _filterStatus = 'semua';

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(adminFieldsProvider);

    return SafeArea(
      child: Column(
        children: [
          // ─── App Bar ──────────────────────────────────────────────────
          _buildHeader(),
          // ─── Search & Filter ──────────────────────────────────────────
          _buildSearchFilter(),
          // ─── List ─────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async =>
                  ref.read(adminFieldsProvider.notifier).load(),
              child: fieldsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: _primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (fields) => _buildList(fields),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kelola Lapangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: () => ref.read(adminFieldsProvider.notifier).load(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari lapangan...',
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFFADB5BD), size: 20),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['semua', 'menunggu', 'aktif', 'ditolak'].map((status) {
                final selected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterStatus = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? _primary : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _chipLabel(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF718096),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AdminFieldModel> fields) {
    var filtered = fields.where((f) {
      final matchSearch = f.namaLapangan.toLowerCase().contains(_searchQuery) ||
          f.namaMitra.toLowerCase().contains(_searchQuery) ||
          f.lokasi.toLowerCase().contains(_searchQuery);
      final matchStatus =
          _filterStatus == 'semua' || f.statusVerifikasi == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada lapangan ditemukan',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildFieldCard(filtered[i]),
    );
  }

  Widget _buildFieldCard(AdminFieldModel field) {
    final statusColor = _statusColor(field.statusVerifikasi);
    final statusLabel = _statusLabel(field.statusVerifikasi);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_soccer,
                    color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.namaLapangan,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      field.namaMitra,
                      style: const TextStyle(
                          color: Color(0xFF718096), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info row
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _infoChip(Icons.location_on_outlined, field.lokasi),
              _infoChip(Icons.category_outlined, field.jenis),
              _infoChip(Icons.attach_money_rounded,
                  'Rp ${_formatHarga(field.hargaPerJam)}/jam'),
            ],
          ),
          // Action buttons for "menunggu"
          if (field.statusVerifikasi == 'menunggu') ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(field, 'ditolak'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(field, 'aktif'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF718096)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
      ],
    );
  }

  Future<void> _updateStatus(AdminFieldModel field, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(status == 'aktif' ? 'Setujui Lapangan' : 'Tolak Lapangan'),
        content: Text(
          status == 'aktif'
              ? 'Setujui lapangan "${field.namaLapangan}"?'
              : 'Tolak lapangan "${field.namaLapangan}"?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'aktif' ? _primary : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(status == 'aktif' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(adminFieldsProvider.notifier).updateVerifikasi(
            fieldId: field.fieldId,
            mitraUid: field.mitraUid,
            status: status,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'aktif'
              ? 'Lapangan berhasil disetujui'
              : 'Lapangan berhasil ditolak'),
          backgroundColor: status == 'aktif' ? _primary : Colors.red,
        ));
      }
    }
  }

  String _chipLabel(String s) {
    switch (s) {
      case 'semua':
        return 'Semua';
      case 'menunggu':
        return 'Menunggu';
      case 'aktif':
        return 'Aktif';
      case 'ditolak':
        return 'Ditolak';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'aktif':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return const Color(0xFFFFB74D);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'aktif':
        return 'Aktif';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  String _formatHarga(int h) {
    if (h >= 1000000) return '${(h / 1000000).toStringAsFixed(1)}jt';
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(0)}rb';
    return h.toString();
  }
}
