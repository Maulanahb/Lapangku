import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/favorite_service.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

// Provider utama untuk memanggil FavoriteService
final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

// Mengecek apakah suatu lapangan sudah difavoritkan oleh user (secara real-time)
final isFavoritedProvider = StreamProvider.family<bool, String>((ref, fieldId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);
  final service = ref.watch(favoriteServiceProvider);
  return service.watchIsFavorited(user.uid, fieldId);
});

// Mengambil seluruh daftar ID lapangan favorit milik user (secara real-time)
final favoriteIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final service = ref.watch(favoriteServiceProvider);
  return service.watchFavoriteIds(user.uid);
});

// Mengambil total jumlah lapangan yang difavoritkan user (misal untuk ditampilkan di profil)
final favoritesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;
  final service = ref.watch(favoriteServiceProvider);
  return service.getFavoritesCount(user.uid);
});
