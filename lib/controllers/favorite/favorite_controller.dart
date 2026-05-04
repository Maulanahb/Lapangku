import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/favorite_service.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

/// Provider untuk FavoriteService
final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

/// Stream provider: apakah sebuah field sudah difavoritkan?
/// Parameter: fieldId
final isFavoritedProvider = StreamProvider.family<bool, String>((ref, fieldId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);
  final service = ref.watch(favoriteServiceProvider);
  return service.watchIsFavorited(user.uid, fieldId);
});

/// Stream provider: daftar ID field favorit user
final favoriteIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final service = ref.watch(favoriteServiceProvider);
  return service.watchFavoriteIds(user.uid);
});

/// Provider untuk jumlah favorit (untuk profil)
final favoritesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;
  final service = ref.watch(favoriteServiceProvider);
  return service.getFavoritesCount(user.uid);
});
