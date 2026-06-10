import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_payout_model.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_revenue_provider.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraPayoutRequestSheet extends ConsumerStatefulWidget {
  final int availableBalance;
  final MitraProfileModel profile;

  const MitraPayoutRequestSheet({
    super.key,
    required this.availableBalance,
    required this.profile,
  });

  @override
  ConsumerState<MitraPayoutRequestSheet> createState() =>
      _MitraPayoutRequestSheetState();
}

class _MitraPayoutRequestSheetState
    extends ConsumerState<MitraPayoutRequestSheet> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountStr) ?? 0;

    if (amount <= 0) {
      SnackbarHelper.showError(context, 'Masukkan nominal yang valid');
      return;
    }

    if (amount > widget.availableBalance) {
      SnackbarHelper.showError(context, 'Saldo tidak mencukupi');
      return;
    }

    if (widget.profile.bankName.isEmpty || widget.profile.bankAccount.isEmpty) {
      SnackbarHelper.showError(context,
          'Silakan lengkapi data rekening di menu Profil terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payout = MitraPayoutModel(
        id: '',
        mitraId: widget.profile.id,
        amount: amount,
        bankName: widget.profile.bankName,
        bankAccount: widget.profile.bankAccount,
        bankAccountName: widget.profile.bankAccountName,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      final service = ref.read(mitraServiceProvider);
      await service.requestPayout(payout);
      ref.invalidate(mitraPayoutsProvider(widget.profile.id));
      await ref.read(mitraRevenueProvider.notifier).loadRevenue();

      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Permintaan pencairan dana berhasil dikirim');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBankInfo = widget.profile.bankName.isNotEmpty &&
        widget.profile.bankAccount.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tarik Dana',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo Aktif: ${CurrencyFormatter.format(widget.availableBalance)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Bank Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    hasBankInfo ? AppColors.primaryLight : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasBankInfo
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasBankInfo ? Colors.white : Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasBankInfo
                          ? Icons.account_balance
                          : Icons.warning_amber_rounded,
                      color: hasBankInfo ? AppColors.primary : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasBankInfo
                              ? widget.profile.bankName
                              : 'Rekening belum diatur',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: hasBankInfo
                                ? AppColors.textHeading
                                : Colors.red.shade700,
                          ),
                        ),
                        if (hasBankInfo) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.profile.bankAccount,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            'a.n ${widget.profile.bankAccountName.isNotEmpty ? widget.profile.bankAccountName : widget.profile.MitraName}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (!hasBankInfo) ...[
              const SizedBox(height: 12),
              const Text(
                'Silakan lengkapi data rekening di halaman Profil > Informasi Pribadi sebelum melakukan penarikan.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Nominal Penarikan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _amountController.text = widget.availableBalance.toString();
                  },
                  child: const Text(
                    'Tarik Semua',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (!hasBankInfo || _isLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Konfirmasi Penarikan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
