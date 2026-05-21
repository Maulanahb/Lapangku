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
  static const _secondary = Color(0xFFE0E7FF);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);

  String _filterStatus = 'menunggu';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mitrasAsync = ref.watch(adminAllMitrasProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(mitrasAsync),
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

  Widget _buildHeader(AsyncValue<List<AdminFieldModel>> mitrasAsync) {
    final pendingCount = mitrasAsync.value
            ?.where((m) => m.statusVerifikasi == 'menunggu')
            .length ??
        0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Verifikasi Mitra',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const SizedBox(height: 4),
                    const Text(
                      'Tinjau dan setujui pengajuan mitra baru untuk aktif di platform.',
                      style: TextStyle(fontSize: 14, color: _textGrey),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => ref.read(adminFieldsProvider.notifier).load(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 16, color: Color(0xFF166534)),
                      SizedBox(width: 8),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Cari mitra...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _tabPill('Semua', 'semua'),
                _tabPill('Menunggu ($pendingCount)', 'menunggu'),
                _tabPill('Terverifikasi', 'aktif'),
                _tabPill('Ditolak', 'ditolak'),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _tabPill(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<AdminFieldModel> mitras) {
    final filtered = mitras.where((m) {
      bool statusMatch = _filterStatus == 'semua' ||
          m.statusVerifikasi.toLowerCase().trim() == _filterStatus.toLowerCase().trim();
      bool searchMatch = _searchQuery.isEmpty ||
          m.namaLapangan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.namaMitra.toLowerCase().contains(_searchQuery.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: filtered.isEmpty
          ? const Center(
              child: Text('Tidak ada pengajuan',
                  style: TextStyle(color: _textGrey)))
          : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _buildMitraCard(filtered[index]),
            ),
    );
  }

  Widget _buildMitraCard(AdminFieldModel mitra) {
    final statusVerifikasi = mitra.statusVerifikasi.toLowerCase().trim();
    final dateStr = mitra.createdAt != null
        ? DateFormat('dd MMM yyyy').format(mitra.createdAt!)
        : '-';

    String imageUrl = '';
    if (mitra.photoUrls != null && mitra.photoUrls!.isNotEmpty) {
      imageUrl = mitra.photoUrls!.first;
    }

    // parsing jenis
    List<String> categories = [];
    if (mitra.jenis.isNotEmpty) {
      categories = mitra.jenis
          .split(',')
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image & Status Badge
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 140,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey)))
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusVerifikasi == 'menunggu'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusVerifikasi == 'menunggu'
                            ? 'MENUNGGU'
                            : 'TERVERIFIKASI',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mitra.namaLapangan,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${mitra.namaMitra} • ${mitra.emailPemilik}',
                  style: const TextStyle(fontSize: 13, color: _textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: _textGrey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(mitra.lokasi,
                              style: const TextStyle(
                                  fontSize: 12, color: _textGrey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: _textGrey),
                        const SizedBox(width: 4),
                        Text(dateStr,
                            style: const TextStyle(
                                fontSize: 12, color: _textGrey)),
                      ],
                    ),
                    ...categories.map((cat) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cat,
                            style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 3. Actions Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (statusVerifikasi == 'menunggu') ...[
                SizedBox(
                  width: 120,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(mitra, 'aktif'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B3A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Verifikasi',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: 120,
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _showMitraDetails(mitra),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Lihat Detail',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              if (statusVerifikasi == 'menunggu') ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _updateStatus(mitra, 'ditolak'),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text('Tolak',
                        style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
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

  void _showMitraDetails(AdminFieldModel mitra) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detail Pengajuan Mitra',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSectionTitle('Data Pemilik & Bisnis'),
                        _buildDetailRow('Nama Pemilik', mitra.namaMitra),
                        _buildDetailRow('Email', mitra.emailPemilik),
                        _buildDetailRow('No. Telepon', mitra.phone),
                        _buildDetailRow('Nama Bisnis', mitra.namaLapangan),
                        
                        const SizedBox(height: 16),
                        const Text('Dokumen Identitas', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (mitra.ktpUrl != null)
                              Expanded(child: _buildImageCard('Foto KTP', mitra.ktpUrl!)),
                            if (mitra.ktpUrl != null && mitra.selfieUrl != null)
                              const SizedBox(width: 16),
                            if (mitra.selfieUrl != null)
                              Expanded(child: _buildImageCard('Selfie KTP', mitra.selfieUrl!)),
                          ],
                        ),
                        
                        const Divider(height: 32),
                        
                        _buildDetailSectionTitle('Informasi Lapangan'),
                        _buildDetailRow('Jenis Olahraga', mitra.jenis),
                        _buildDetailRow('Tipe Lapangan', mitra.tipeLapangan),
                        _buildDetailRow('Harga Per Jam', NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(mitra.hargaPerJam)),
                        
                        const SizedBox(height: 8),
                        const Text('Fasilitas', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mitra.fasilitas.map((f) => Chip(
                            label: Text(f, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide(color: Colors.grey.shade300),
                          )).toList(),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w600, color: _textDark)),
                        const SizedBox(height: 4),
                        Text(mitra.deskripsi.isEmpty ? '-' : mitra.deskripsi, style: const TextStyle(color: _textGrey)),
                        
                        const Divider(height: 32),
                        
                        _buildDetailSectionTitle('Lokasi & Operasional'),
                        _buildDetailRow('Alamat', mitra.lokasi),
                        _buildDetailRow('Jam Operasional', mitra.jamOperasional),
                        _buildDetailRow('Hari Operasional', mitra.hariOperasional.join(', ')),
                        
                        const Divider(height: 32),
                        
                        _buildDetailSectionTitle('Foto Lapangan'),
                        if (mitra.photoUrls != null && mitra.photoUrls!.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: mitra.photoUrls!.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    mitra.photoUrls![index],
                                    width: 160,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          const Text('Tidak ada foto', style: TextStyle(color: _textGrey)),
                      ],
                    ),
                  ),
                ),
                // Footer
                if (mitra.statusVerifikasi == 'menunggu')
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateStatus(mitra, 'ditolak');
                          },
                          child: const Text('Tolak Pengajuan', style: TextStyle(color: Color(0xFFDC2626))),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateStatus(mitra, 'aktif');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B6B3A),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Verifikasi Mitra'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: _textGrey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: _textDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: _textGrey)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.error, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
