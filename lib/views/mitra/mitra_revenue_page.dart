import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/mitra/mitra_revenue_provider.dart';

class MitraRevenuePage extends ConsumerStatefulWidget {
  const MitraRevenuePage({super.key});

  @override
  ConsumerState<MitraRevenuePage> createState() => _MitraRevenuePageState();
}

class _MitraRevenuePageState extends ConsumerState<MitraRevenuePage> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _selectDateRange() async {
    final currentRange = ref.read(revenueDateRangeProvider);
    
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: currentRange.start, end: currentRange.end),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B6B3A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(revenueDateRangeProvider.notifier).state = DateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(mitraRevenueProvider);
    final dateRange = ref.watch(revenueDateRangeProvider);
    final dateStr = '${DateFormat('dd MMM yyyy').format(dateRange.start)} - ${DateFormat('dd MMM yyyy').format(dateRange.end)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Laporan Pendapatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Periode Laporan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 18, color: Color(0xFF1B6B3A)),
                  label: const Text('Ubah', style: TextStyle(color: Color(0xFF1B6B3A))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1B6B3A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: revenueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
              error: (err, _) => Center(child: Text('Gagal memuat: $err')),
              data: (revenue) {
                return RefreshIndicator(
                  color: const Color(0xFF1B6B3A),
                  onRefresh: () async {
                    await ref.read(mitraRevenueProvider.notifier).loadRevenue();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Total Pendapatan',
                                value: _currencyFormat.format(revenue.totalRevenue),
                                icon: Icons.account_balance_wallet,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Total Pesanan Selesai',
                                value: '${revenue.totalOrders}',
                                icon: Icons.check_circle_outline,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        const Text('Daftar Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        
                        if (revenue.transactions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text('Belum ada transaksi di periode ini', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: revenue.transactions.length,
                            itemBuilder: (context, index) {
                              final tx = revenue.transactions[index];
                              return _buildTransactionItem(
                                tx.customerName, 
                                tx.fieldName,
                                _currencyFormat.format(tx.amount), 
                                DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String name, String field, String amount, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(field, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF1B6B3A))),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
        ],
      ),
    );
  }
}
