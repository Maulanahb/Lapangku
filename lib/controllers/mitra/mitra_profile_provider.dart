import 'package:flutter_riverpod/flutter_riverpod.dart';

class MitraProfileState {
  final String businessName;
  final String MitraName;
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

  const MitraProfileState({
    this.businessName = 'GOR LapangKu',
    this.MitraName = 'Budi Santoso',
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

  MitraProfileState copyWith({
    String? businessName,
    String? MitraName,
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
    return MitraProfileState(
      businessName: businessName ?? this.businessName,
      MitraName: MitraName ?? this.MitraName,
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

class MitraProfileNotifier extends StateNotifier<MitraProfileState> {
  MitraProfileNotifier() : super(const MitraProfileState());

  void toggleNotificationOrder() {
    state = state.copyWith(notificationOrder: !state.notificationOrder);
  }

  void toggleNotificationPromo() {
    state = state.copyWith(notificationPromo: !state.notificationPromo);
  }

  Future<void> updateProfile({
    required String businessName,
    required String MitraName,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API
      state = state.copyWith(
        businessName: businessName,
        MitraName: MitraName,
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

final MitraProfileProvider = StateNotifierProvider<MitraProfileNotifier, MitraProfileState>((ref) {
  return MitraProfileNotifier();
});
