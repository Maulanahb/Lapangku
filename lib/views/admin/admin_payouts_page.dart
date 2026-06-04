import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class AdminPayoutsPage extends ConsumerStatefulWidget {
  const AdminPayoutsPage({super.key});

  @override
  ConsumerState<AdminPayoutsPage> createState() => _AdminPayoutsPageState();
}

class _AdminPayoutsPageState extends ConsumerState<AdminPayoutsPage> {
  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, pending, processing, completed, rejected

  @override
  Widget build(BuildContext context) {
    final payoutsAsync = ref.watch(adminPayoutsProvider);

    return Column(
      children: [
        _buildHeader(),
        _buildSearchFilter(),
        Expanded(
          child: Container(
            color: AppColors.backgroundPage,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(adminPayoutsProvider),
              child: payoutsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat data',
                  subtitle: e.toString(),
                ),
                data: (payouts) {
                  final filtered = payouts.where((p) {
                    final bankAccountName = (p['bankAccountName'] ?? '').toString().toLowerCase();
                    final bankName = (p['bankName'] ?? '').toString().toLowerCase();
                    final id = (p['id'] ?? '').toString().toLowerCase();
                    
                    final matchSearch = bankAccountName.contains(_searchQuery) ||
                                        bankName.contains(_searchQuery) ||
                                        id.contains(_searchQuery);
                    final matchStatus = _selectedStatus == 'all' || p['status'] == _selectedStatus;
                    
                    return matchSearch && matchStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        EmptyStateWidget(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Tidak ada data pencairan',
                          subtitle: 'Data pencairan yang sesuai dengan filter tidak ditemukan.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = filtered[index];
                      return _buildPayoutCard(data);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Pencairan Dana',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textHeading,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pantau seluruh permohonan pencairan dana mitra.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => ref.refresh(adminPayoutsProvider),
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
    );
  }

  Widget _buildSearchFilter() {
    final filters = [
      {'label': 'Semua', 'value': 'all'},
      {'label': 'Menunggu', 'value': 'pending'},
      {'label': 'Diproses', 'value': 'processing'},
      {'label': 'Selesai', 'value': 'completed'},
      {'label': 'Ditolak', 'value': 'rejected'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari nama, bank, atau ID...',
              hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.hint, size: 20),
              filled: true,
              fillColor: AppColors.backgroundInput,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = _selectedStatus == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStatus = f['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
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

  Widget _buildPayoutCard(Map<String, dynamic> data) {
    final amount = data['amount'] ?? 0;
    final status = data['status'] ?? 'pending';
    final bankName = data['bankName'] ?? '-';
    final bankAccount = data['bankAccount'] ?? '-';
    final bankAccountName = data['bankAccountName'] ?? '-';
    final dynamic reqAt = data['requestedAt'];
    final date = reqAt != null ? reqAt.toDate() : DateTime.now();

    Color statusColor;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF10B981); // Match terverifikasi color
        statusText = 'Selesai';
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626); // Match tolak color
        statusText = 'Ditolak';
        break;
      case 'processing':
        statusColor = const Color(0xFFF59E0B); // Match menunggu color
        statusText = 'Diproses';
        break;
      default:
        statusColor = const Color(0xFF4285F4); // Blue
        statusText = 'Menunggu';
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
          // 1. Image / Icon & Status Badge
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 140,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.primary.withOpacity(0.05),
                    child: const Icon(Icons.account_balance_wallet,
                        size: 40, color: AppColors.primary),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
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
                  CurrencyFormatter.format(amount),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Oleh: $bankAccountName',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
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
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM yyyy, HH:mm').format(date),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(bankName,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.numbers_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(bankAccount,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
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
              if (status == 'pending') ...[
                SizedBox(
                  width: 120,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(data['id'], 'processing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Proses',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(data['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Tolak',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else if (status == 'processing') ...[
                SizedBox(
                  width: 120,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _showCompleteDialog(data['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B3A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Selesai',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else if (status == 'completed' && data['proofUrl'] != null) ...[
                SizedBox(
                  width: 120,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.network(data['proofUrl']),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Tutup')),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Lihat Bukti',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String payoutId, String status) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.updatePayoutStatus(payoutId: payoutId, status: status);
      if (mounted) SnackbarHelper.showSuccess(context, 'Status berhasil diperbarui');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal memperbarui status: $e');
    }
  }

  Future<void> _showCompleteDialog(String payoutId) async {
    // For MVP, we might just mark as completed without actual proof upload,
    // or just show a success modal. Let's just mark it completed for now.
    try {
      final service = ref.read(adminServiceProvider);
      await service.updatePayoutStatus(
        payoutId: payoutId, 
        status: 'completed',
        notes: 'Transfer manual selesai',
      );
      if (mounted) SnackbarHelper.showSuccess(context, 'Pencairan berhasil diselesaikan');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal menyelesaikan pencairan: $e');
    }
  }
}

