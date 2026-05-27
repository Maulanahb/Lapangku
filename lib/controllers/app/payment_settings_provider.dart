import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/app/payment_settings_model.dart';
import 'package:lapangku/core/services/firestore_service.dart';

/// Provider untuk mengambil data konfigurasi pembayaran secara global dari Firestore.
final paymentSettingsProvider = FutureProvider<PaymentSettingsModel>((ref) async {
  try {
    final db = FirestoreService.instance;
    final doc = await db.collection('app_settings').doc('payment_info').get();
    
    if (doc.exists && doc.data() != null) {
      return PaymentSettingsModel.fromMap(doc.data()!);
    }
  } catch (e) {
    // Return default if error
  }
  
  // Return default if document doesn't exist or there was an error
  return const PaymentSettingsModel(
    bankName: 'BCA',
    accountNumber: '123-456-789-0',
    accountName: 'LapangKu Indonesia',
    qrisUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=LapangKu_Dummy_QRIS',
  );
});
