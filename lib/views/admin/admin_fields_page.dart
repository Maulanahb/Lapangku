import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';

class AdminFieldsPage extends ConsumerStatefulWidget {
  const AdminFieldsPage({super.key});

  @override
  ConsumerState<AdminFieldsPage> createState() => _AdminFieldsPageState();
}

class _AdminFieldsPageState extends ConsumerState<AdminFieldsPage> {
  static const _primary = Color(0xFF1B6B3A);
  String _filterStatus = 'menunggu';

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(adminFieldsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(fieldsAsync),
        _buildTabs(fieldsAsync),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: fieldsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (fields) => _buildContent(fields),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AsyncValue<List<AdminFieldModel>> fieldsAsync) {
    int pendingCount = 0;
    if (fieldsAsync.hasValue) {
      pendingCount = fieldsAsync.value!.where((f) => f.statusVerifikasi == 'menunggu').length;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifikasi Mitra',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tinjau pengajuan pendaftaran mitra baru.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(adminFieldsProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Segarkan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: _primary.withOpacity(0.4),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFEF3C7), const Color(0xFFFEF3C7).withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notification_important_rounded, color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount Menunggu Verifikasi',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(AsyncValue<List<AdminFieldModel>> fieldsAsync) {
    int pendingCount = 0;
    if (fieldsAsync.hasValue) {
      pendingCount = fieldsAsync.value!.where((f) => f.statusVerifikasi == 'menunggu').length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          _buildTabItem('Semua', 'semua', null),
          const SizedBox(width: 12),
          _buildTabItem('Menunggu ($pendingCount)', 'menunggu', pendingCount),
          const SizedBox(width: 12),
          _buildTabItem('Terverifikasi', 'aktif', null),
          const SizedBox(width: 12),
          _buildTabItem('Ditolak', 'ditolak', null),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String status, int? count) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<AdminFieldModel> fields) {
    final filtered = fields.where((f) {
      if (_filterStatus == 'semua') return true;
      return f.statusVerifikasi.toLowerCase().trim() == _filterStatus.toLowerCase().trim();
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 48,
                ),
                child: DataTable(
                  horizontalMargin: 24,
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                  dataRowMaxHeight: 72,
                  dataRowMinHeight: 72,
                  columns: const [
                    DataColumn(label: Text('NAMA BISNIS/LAPANGAN', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('PEMILIK', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('LOKASI', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('TANGGAL PENGAJUAN', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('AKSI', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold))),
                  ],
                  rows: filtered.map((f) => _buildRow(f)).toList(),
                ),
              ),
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey)),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Menampilkan ${filtered.length} pengajuan', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () {}, color: Colors.grey),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                        child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () {}, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(AdminFieldModel field) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateStr = field.createdAt != null ? dateFormat.format(field.createdAt!) : '-';
    
    String timeAgo = '-';
    Color timeAgoColor = Colors.grey;
    if (field.createdAt != null) {
      final diff = DateTime.now().difference(field.createdAt!);
      if (diff.inDays == 0) {
        timeAgo = 'Hari ini';
        timeAgoColor = const Color(0xFF10B981);
      } else {
        timeAgo = '${diff.inDays} hari lalu';
        timeAgoColor = const Color(0xFFF59E0B);
      }
    }

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_soccer, color: _primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.namaLapangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                Text(field.jenis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ],
        )),
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.namaMitra, style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
            Text(field.emailPemilik, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        )),
        DataCell(Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(field.lokasi, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
          ],
        )),
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
            Text(timeAgo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: timeAgoColor)),
          ],
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (field.statusVerifikasi.toLowerCase().trim() == 'menunggu') ...[
              ElevatedButton.icon(
                onPressed: () => _updateStatus(field, 'aktif'),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Verifikasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _updateStatus(field, 'ditolak'),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (field.statusVerifikasi.toLowerCase().trim() != 'menunggu') ...[
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: field.statusVerifikasi == 'aktif' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                   borderRadius: BorderRadius.circular(6),
                 ),
                 child: Text(
                   field.statusVerifikasi == 'aktif' ? 'Terverifikasi' : 'Ditolak',
                   style: TextStyle(
                     color: field.statusVerifikasi == 'aktif' ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                     fontWeight: FontWeight.bold,
                     fontSize: 12,
                   ),
                 ),
               ),
               const SizedBox(width: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: const Icon(Icons.remove_red_eye, size: 16, color: Color(0xFF1E3A8A)),
                onPressed: () {
                  // View details
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        )),
      ],
    );
  }

  Future<void> _updateStatus(AdminFieldModel field, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'aktif' ? 'Verifikasi Pemilik Lapangan' : 'Tolak Pemilik Lapangan'),
        content: Text(
          status == 'aktif'
              ? 'Anda yakin ingin memverifikasi pemilik lapangan ini?'
              : 'Anda yakin ingin menolak pemilik lapangan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'aktif' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            child: Text(status == 'aktif' ? 'Verifikasi' : 'Tolak'),
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
    }
  }
}
