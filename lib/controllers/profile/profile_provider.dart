import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  final int totalOrders;
  final double rating;
  final int favoritesCount;
  final bool isNotificationOn;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    this.totalOrders = 0,
    this.rating = 0.0,
    this.favoritesCount = 0,
    this.isNotificationOn = true,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    int? totalOrders,
    double? rating,
    int? favoritesCount,
    bool? isNotificationOn,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileState(
      totalOrders: totalOrders ?? this.totalOrders,
      rating: rating ?? this.rating,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isNotificationOn: isNotificationOn ?? this.isNotificationOn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState(isLoading: true)) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(
      totalOrders: 12,
      rating: 4.9,
      favoritesCount: 3,
      isLoading: false,
    );
  }

  void toggleNotification() {
    state = state.copyWith(isNotificationOn: !state.isNotificationOn);
  }
}

final profileStateProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
