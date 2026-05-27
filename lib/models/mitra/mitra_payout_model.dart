import 'package:cloud_firestore/cloud_firestore.dart';

class MitraPayoutModel {
  final String id;
  final String mitraId;
  final int amount;
  final String bankName;
  final String bankAccount;
  final String bankAccountName;
  final String status; // 'pending', 'completed', 'rejected'
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? proofUrl;
  final String? notes;

  const MitraPayoutModel({
    required this.id,
    required this.mitraId,
    required this.amount,
    required this.bankName,
    required this.bankAccount,
    required this.bankAccountName,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.proofUrl,
    this.notes,
  });

  factory MitraPayoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return MitraPayoutModel(
      id: doc.id,
      mitraId: data['mitraId'] ?? '',
      amount: data['amount'] ?? 0,
      bankName: data['bankName'] ?? '',
      bankAccount: data['bankAccount'] ?? '',
      bankAccountName: data['bankAccountName'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      proofUrl: data['proofUrl'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mitraId': mitraId,
      'amount': amount,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'bankAccountName': bankAccountName,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt!),
      if (proofUrl != null) 'proofUrl': proofUrl,
      if (notes != null) 'notes': notes,
    };
  }

  MitraPayoutModel copyWith({
    String? id,
    String? mitraId,
    int? amount,
    String? bankName,
    String? bankAccount,
    String? bankAccountName,
    String? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? proofUrl,
    String? notes,
  }) {
    return MitraPayoutModel(
      id: id ?? this.id,
      mitraId: mitraId ?? this.mitraId,
      amount: amount ?? this.amount,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      proofUrl: proofUrl ?? this.proofUrl,
      notes: notes ?? this.notes,
    );
  }
}
