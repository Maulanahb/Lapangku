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
  String _selectedStatus = 'all'; // all, pending, processing, completed, rejected

  @override
  Widget build(BuildContext context) {
    final payoutsAsync = ref.watch(adminPayoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text('Kelola Pencairan Dana', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: payoutsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Gagal memuat data',
                subtitle: e.toString(),
              ),
              data: (payouts) {
                final filtered = _selectedStatus == 'all'
                    ? payouts
                    : payouts.where((p) => p['status'] == _selectedStatus).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Tidak ada data pencairan',
                    subtitle: 'Data pencairan yang sesuai dengan filter tidak ditemukan.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index];
                    return _buildPayoutCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Semua', 'value': 'all'},
      {'label': 'Menunggu', 'value': 'pending'},
      {'label': 'Diproses', 'value': 'processing'},
      {'label': 'Selesai', 'value': 'completed'},
      {'label': 'Ditolak', 'value': 'rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              onSelected: (val) {
                if (val) setState(() => _selectedStatus = f['value']!);
              },
            ),
          );
        }).toList(),
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
        statusColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusText = 'Diproses';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Menunggu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Tanggal', DateFormat('dd MMM yyyy, HH:mm').format(date)),
            _buildInfoRow('Bank', bankName),
            _buildInfoRow('No. Rekening', bankAccount),
            _buildInfoRow('Atas Nama', bankAccountName),
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
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tandai Selesai & Upload Bukti', style: TextStyle(color: Colors.white)),
                ),
              ),
            ] else if (status == 'completed' && data['proofUrl'] != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: View proof (can just show dialog with image network)
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: Image.network(data['proofUrl']),
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
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
