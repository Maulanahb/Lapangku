import 'package:flutter_riverpod/flutter_riverpod.dart';

class OwnerProfileState {
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final bool isVerified;
  final int totalFields;
  final int totalOrders;
  final double rating;
  final bool notificationOrder;
  final bool notificationPromo;
  final Map<String, String>? bankAccount; // e.g. {'bank': 'BCA', 'account': '123-456-789'}
  final bool isLoading;
  final String? errorMessage;

  const OwnerProfileState({
    this.businessName = 'GOR LapangKu',
    this.ownerName = 'Budi Santoso',
    this.email = 'budi@gorlapangku.com',
    this.phone = '081234567890',
    this.isVerified = true,
    this.totalFields = 3,
    this.totalOrders = 150,
    this.rating = 4.8,
    this.notificationOrder = true,
    this.notificationPromo = false,
    this.bankAccount = const {'bank': 'BCA', 'account': '123-456-789'},
    this.isLoading = false,
    this.errorMessage,
  });

  OwnerProfileState copyWith({
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    bool? isVerified,
    int? totalFields,
    int? totalOrders,
    double? rating,
    bool? notificationOrder,
    bool? notificationPromo,
    Map<String, String>? bankAccount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnerProfileState(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      totalFields: totalFields ?? this.totalFields,
      totalOrders: totalOrders ?? this.totalOrders,
      rating: rating ?? this.rating,
      notificationOrder: notificationOrder ?? this.notificationOrder,
      notificationPromo: notificationPromo ?? this.notificationPromo,
      bankAccount: bankAccount ?? this.bankAccount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OwnerProfileNotifier extends StateNotifier<OwnerProfileState> {
  OwnerProfileNotifier() : super(const OwnerProfileState());

  void toggleNotificationOrder() {
    state = state.copyWith(notificationOrder: !state.notificationOrder);
  }

  void toggleNotificationPromo() {
    state = state.copyWith(notificationPromo: !state.notificationPromo);
  }

  Future<void> updateProfile({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API
      state = state.copyWith(
        businessName: businessName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memperbarui profil: $e',
      );
      rethrow;
    }
  }

  Future<void> updateBankInfo(String bank, String account) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API
      state = state.copyWith(
        bankAccount: {'bank': bank, 'account': account},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memperbarui rekening: $e',
      );
      rethrow;
    }
  }
}

final ownerProfileProvider = StateNotifierProvider<OwnerProfileNotifier, OwnerProfileState>((ref) {
  return OwnerProfileNotifier();
});
