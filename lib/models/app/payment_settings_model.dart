class PaymentSettingsModel {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String qrisUrl;

  const PaymentSettingsModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.qrisUrl,
  });

  factory PaymentSettingsModel.fromMap(Map<String, dynamic> map) {
    return PaymentSettingsModel(
      bankName: map['bankName']?.toString() ?? 'BCA',
      accountNumber: map['accountNumber']?.toString() ?? '123-456-789-0',
      accountName: map['accountName']?.toString() ?? 'LapangKu Indonesia',
      qrisUrl: map['qrisUrl']?.toString() ?? 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=LapangKu_Dummy_QRIS',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'qrisUrl': qrisUrl,
    };
  }
}
