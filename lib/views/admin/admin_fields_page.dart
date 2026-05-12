import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';

class AdminFieldsPage extends ConsumerStatefulWidget {
  const AdminFieldsPage({super.key});

  @override
  ConsumerState<AdminFieldsPage> createState() => _AdminFieldsPageState();
}

class _AdminFieldsPageState extends ConsumerState<AdminFieldsPage> {
  static const _primary = Color(0xFF1B6B3A);
  static const _secondary = Color(0xFFE0E7FF);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);

  String _filterStatus = 'menunggu';

  @override
  Widget build(BuildContext context) {
    final mitrasAsync = ref.watch(adminAllMitrasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeader(),
          _buildHeaderInfo(mitrasAsync),
          _buildTabs(),
          Expanded(
            child: mitrasAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (mitras) => _buildContent(mitras),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Verifikasi Mitra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.read(adminFieldsProvider.notifier).load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.notifications_none, color: _textDark),
              const SizedBox(width: 16),
              const Icon(Icons.grid_view_rounded, color: _textDark),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 16,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?u=admin'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(AsyncValue<List<AdminFieldModel>> mitrasAsync) {
    final pendingCount = mitrasAsync.value
            ?.where((m) => m.statusVerifikasi == 'menunggu')
            .length ??
        0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Verifikasi Mitra',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pendingCount Menunggu Verifikasi',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tinjau dan setujui pengajuan mitra baru untuk aktif di platform.',
            style: TextStyle(fontSize: 14, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _tabPill('Semua', 'semua'),
          const SizedBox(width: 12),
          _tabPill('Menunggu (${_getPendingCount()})', 'menunggu'),
          const SizedBox(width: 12),
          _tabPill('Terverifikasi', 'aktif'),
          const SizedBox(width: 12),
          _tabPill('Ditolak', 'ditolak'),
        ],
      ),
    );
  }

  int _getPendingCount() {
    final mitrasAsync = ref.read(adminAllMitrasProvider);
    return mitrasAsync.value
            ?.where((m) => m.statusVerifikasi == 'menunggu')
            .length ??
        0;
  }

  Widget _tabPill(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: isSelected ? _primary : Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<AdminFieldModel> mitras) {
    final filtered = mitras.where((m) {
      if (_filterStatus == 'semua') return true;
      return m.statusVerifikasi.toLowerCase().trim() ==
          _filterStatus.toLowerCase().trim();
    }).toList();

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('MITRA / BISNIS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4338CA)))),
                Expanded(
                    flex: 2,
                    child: Text('PEMILIK',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4338CA)))),
                Expanded(
                    flex: 2,
                    child: Text('LOKASI',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4338CA)))),
                Expanded(
                    flex: 2,
                    child: Text('TANGGAL PENGAJUAN',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4338CA)))),
                Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('AKSI',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4338CA))),
                    )),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Tidak ada pengajuan',
                        style: TextStyle(color: _textGrey)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, index) =>
                        _buildTableRow(filtered[index]),
                  ),
          ),
          // Pagination Placeholder
          _buildPagination(filtered.length),
        ],
      ),
    );
  }

  Widget _buildTableRow(AdminFieldModel mitra) {
    final statusVerifikasi = mitra.statusVerifikasi.toLowerCase().trim();
    final dateStr = mitra.createdAt != null
        ? DateFormat('dd MMM yyyy').format(mitra.createdAt!)
        : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // MITRA / BISNIS
          Expanded(
            flex: 3,
            child: Text(mitra.namaLapangan,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _textDark)),
          ),
          // PEMILIK
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mitra.namaMitra,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _textDark)),
                Text(mitra.emailPemilik,
                    style: const TextStyle(fontSize: 12, color: _textGrey)),
              ],
            ),
          ),
          // LOKASI
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: _textGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(mitra.lokasi,
                      style: const TextStyle(fontSize: 13, color: _textGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // TANGGAL PENGAJUAN
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 14,
                        color: _textDark,
                        fontWeight: FontWeight.w500)),
                Text(
                  _getTimeAgo(mitra.createdAt ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusVerifikasi == 'menunggu'
                        ? const Color(0xFFD97706)
                        : _textGrey,
                    fontWeight: statusVerifikasi == 'menunggu'
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // AKSI
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (statusVerifikasi == 'menunggu') ...[
                  _actionButton(
                    onPressed: () => _updateStatus(mitra, 'aktif'),
                    icon: Icons.check,
                    label: 'Verifikasi',
                    color: const Color(0xFF1B6B3A),
                    isFilled: true,
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    onPressed: () => _updateStatus(mitra, 'ditolak'),
                    icon: Icons.close,
                    label: 'Tolak',
                    color: const Color(0xFFEF4444),
                    isFilled: false,
                  ),
                ] else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusVerifikasi == 'aktif'
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusVerifikasi == 'aktif' ? 'Terverifikasi' : 'Ditolak',
                      style: TextStyle(
                        color: statusVerifikasi == 'aktif'
                            ? const Color(0xFF065F46)
                            : const Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                _iconButton(
                    Icons.remove_red_eye_outlined, const Color(0xFF1E3A8A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isFilled,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFilled ? color : Colors.white,
        foregroundColor: isFilled ? Colors.white : color,
        elevation: 0,
        side: isFilled ? null : BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: () {},
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPagination(int count) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Menampilkan 1-$count dari $count pengajuan',
              style: const TextStyle(color: _textGrey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageIcon(Icons.chevron_left, false),
              const SizedBox(width: 8),
              _pageNumber('1', true),
              const SizedBox(width: 8),
              _pageNumber('2', false),
              const SizedBox(width: 8),
              _pageNumber('3', false),
              const SizedBox(width: 8),
              _pageIcon(Icons.chevron_right, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageIcon(IconData icon, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon,
          size: 18, color: active ? _textDark : Colors.grey.shade400),
    );
  }

  Widget _pageNumber(String num, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF064E3B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          num,
          style: TextStyle(
            color: active ? Colors.white : _textGrey,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(AdminFieldModel mitra, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(status == 'aktif' ? 'Verifikasi Mitra' : 'Tolak Mitra'),
        content: Text(
          status == 'aktif'
              ? 'Anda yakin ingin memverifikasi pemilik bisnis "${mitra.namaLapangan}"?'
              : 'Anda yakin ingin menolak pemilik bisnis "${mitra.namaLapangan}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'aktif'
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(status == 'aktif' ? 'Verifikasi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(adminFieldsProvider.notifier).updateVerifikasi(
            mitraId: mitra.mitraId,
            status: status,
          );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) {
      final duration = now.difference(dateTime);
      if (duration.inHours > 0) return '${duration.inHours} jam lalu';
      if (duration.inMinutes > 0) return '${duration.inMinutes} menit lalu';
      return 'Baru saja';
    } else if (diff == 1) {
      return 'Kemarin';
    } else {
      return '$diff hari lalu';
    }
  }
}
