import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/network_image_web.dart';

class AdminFieldsPage extends ConsumerStatefulWidget {
  const AdminFieldsPage({super.key});

  @override
  ConsumerState<AdminFieldsPage> createState() => _AdminFieldsPageState();
}

class _AdminFieldsPageState extends ConsumerState<AdminFieldsPage> {
  static const _primary = AppColors.primary;
  static const _secondary = Color(0xFFE0E7FF);
  static const _textDark = AppColors.textHeading;
  static const _textGrey = AppColors.textSecondary;

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
      backgroundColor: AppColors.backgroundPage,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(mitrasAsync),
          Expanded(
            child: mitrasAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textHeading,
                            letterSpacing: -0.5,
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
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.read(adminFieldsProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.hovered) ? AppColors.primary : Colors.grey.shade100),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.hovered) ? Colors.white : AppColors.primary),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Cari mitra...',
                hintStyle: TextStyle(color: AppColors.hint, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppColors.hint, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
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
                      ? WebSafeNetworkImage(
                          url: imageUrl,
                          fit: BoxFit.cover,
                          width: 140,
                          height: 100,
                        )
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
    final statusVerifikasi = mitra.statusVerifikasi.toLowerCase().trim();

    Color statusColor;
    Color statusBg;
    String statusLabel;

    switch (statusVerifikasi) {
      case 'aktif':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFD1FAE5);
        statusLabel = 'Terverifikasi';
        break;
      case 'ditolak':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusLabel = 'Menunggu Verifikasi';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Premium Header ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B6B3A), Color(0xFF2D9052)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        // Avatar / Photo
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (mitra.photoUrls != null &&
                                    mitra.photoUrls!.isNotEmpty)
                                ? WebSafeNetworkImage(
                                    url: mitra.photoUrls!.first,
                                    fit: BoxFit.cover,
                                    width: 56,
                                    height: 56,
                                  )
                                : const Icon(Icons.store_rounded,
                                    color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mitra.namaLapangan,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    mitra.namaMitra,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Body ─────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Info Pemilik
                          _premiumSection(
                            icon: Icons.person_rounded,
                            title: 'Data Pemilik & Bisnis',
                            color: const Color(0xFF6366F1),
                            child: Column(
                              children: [
                                _infoRow(Icons.person_outline_rounded,
                                    'Nama Pemilik', mitra.namaMitra),
                                _infoRow(Icons.email_outlined, 'Email',
                                    mitra.emailPemilik),
                                _infoRow(Icons.phone_outlined, 'Telepon',
                                    mitra.phone.isEmpty ? '-' : mitra.phone),
                                _infoRow(Icons.store_outlined, 'Nama Bisnis',
                                    mitra.namaLapangan),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Section: Dokumen Identitas
                          _premiumSection(
                            icon: Icons.badge_rounded,
                            title: 'Dokumen Identitas',
                            color: const Color(0xFF0EA5E9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (mitra.ktpUrl == null &&
                                    mitra.selfieUrl == null)
                                  Text(
                                    'Tidak ada dokumen diunggah',
                                    style:
                                        TextStyle(color: Colors.grey.shade500),
                                  )
                                else
                                  Row(
                                    children: [
                                      if (mitra.ktpUrl != null)
                                        Expanded(
                                            child: _premiumImageCard(
                                                'Foto KTP', mitra.ktpUrl!)),
                                      if (mitra.ktpUrl != null &&
                                          mitra.selfieUrl != null)
                                        const SizedBox(width: 12),
                                      if (mitra.selfieUrl != null)
                                        Expanded(
                                            child: _premiumImageCard(
                                                'Selfie dengan KTP',
                                                mitra.selfieUrl!)),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Section: Informasi Lapangan
                          _premiumSection(
                            icon: Icons.sports_soccer_rounded,
                            title: 'Informasi Lapangan',
                            color: const Color(0xFF10B981),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(Icons.sports_rounded, 'Jenis Olahraga',
                                    mitra.jenis.isEmpty ? '-' : mitra.jenis),
                                _infoRow(Icons.category_outlined,
                                    'Tipe Lapangan',
                                    mitra.tipeLapangan.isEmpty
                                        ? '-'
                                        : mitra.tipeLapangan),
                                _infoRow(
                                    Icons.attach_money_rounded,
                                    'Harga Per Jam',
                                    NumberFormat.currency(
                                            locale: 'id',
                                            symbol: 'Rp',
                                            decimalDigits: 0)
                                        .format(mitra.hargaPerJam)),
                                if (mitra.fasilitas.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 140,
                                        child: Text(
                                          'Fasilitas',
                                          style: TextStyle(
                                              color: _textGrey,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: mitra.fasilitas
                                              .map((f) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color(0xFFF0FDF4),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFFBBF7D0)),
                                                    ),
                                                    child: Text(
                                                      f,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Color(0xFF065F46),
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (mitra.deskripsi.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 140,
                                        child: Text(
                                          'Deskripsi',
                                          style: TextStyle(
                                              color: _textGrey,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(mitra.deskripsi,
                                            style: const TextStyle(
                                                color: _textDark,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Section: Lokasi & Operasional
                          _premiumSection(
                            icon: Icons.location_on_rounded,
                            title: 'Lokasi & Operasional',
                            color: const Color(0xFFF59E0B),
                            child: Column(
                              children: [
                                _infoRow(Icons.map_outlined, 'Alamat',
                                    mitra.lokasi.isEmpty ? '-' : mitra.lokasi),
                                _infoRow(
                                    Icons.access_time_rounded,
                                    'Jam Operasional',
                                    mitra.jamOperasional.isEmpty
                                        ? '-'
                                        : mitra.jamOperasional),
                                _infoRow(
                                    Icons.calendar_month_outlined,
                                    'Hari Operasional',
                                    mitra.hariOperasional.isEmpty
                                        ? '-'
                                        : mitra.hariOperasional.join(', ')),
                              ],
                            ),
                          ),

                          // Section: Foto Lapangan
                          if (mitra.photoUrls != null &&
                              mitra.photoUrls!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _premiumSection(
                              icon: Icons.photo_library_rounded,
                              title: 'Foto Lapangan',
                              color: const Color(0xFFEC4899),
                              child: SizedBox(
                                height: 130,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: mitra.photoUrls!.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        // Copy URL to clipboard
                                        Clipboard.setData(ClipboardData(
                                            text: mitra.photoUrls![index]));
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: WebSafeNetworkImage(
                                          url: mitra.photoUrls![index],
                                          width: 180,
                                          height: 130,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Footer Actions ──────────────────────────────────
                  if (statusVerifikasi == 'menunggu')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24)),
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateStatus(mitra, 'ditolak');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Tolak Pengajuan',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateStatus(mitra, 'aktif');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B6B3A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Verifikasi Mitra',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _premiumSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border:
                  Border(bottom: BorderSide(color: color.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  color: _textGrey, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: _textDark, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumImageCard(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12, color: _textGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: WebSafeNetworkImage(
            url: url,
            height: 110,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
