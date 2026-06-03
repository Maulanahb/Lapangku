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
        statusColor = const Color(0xFF1B6B3A); // Green
        statusText = 'Selesai';
        break;
      case 'rejected':
        statusColor = const Color(0xFFE53935); // Red
        statusText = 'Ditolak';
        break;
      case 'processing':
        statusColor = const Color(0xFFFF9800); // Orange
        statusText = 'Diproses';
        break;
      default:
        statusColor = const Color(0xFF4285F4); // Blue
        statusText = 'Menunggu';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Oleh: $bankAccountName',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
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
                  statusText,
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
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detailItem(
                    Icons.calendar_today_outlined, 'Tanggal', DateFormat('dd MMM yyyy, HH:mm').format(date)),
              ),
              Expanded(
                child: _detailItem(Icons.account_balance_outlined, 'Bank', bankName),
              ),
              Expanded(
                child: _detailItem(Icons.numbers_outlined, 'No. Rek', bankAccount),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(data['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(data['id'], 'processing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Proses', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else if (status == 'processing') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCompleteDialog(data['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Tandai Selesai & Upload Bukti', style: TextStyle(color: Colors.white)),
              ),
            ),
          ] else if (status == 'completed' && data['proofUrl'] != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      content: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(data['proofUrl']),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long, color: AppColors.primary),
                label: const Text('Lihat Bukti Transfer', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
          overflow: TextOverflow.ellipsis,
        ),
      ],
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

