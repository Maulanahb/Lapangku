import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/favorite/favorite_controller.dart';
import 'package:lapangku/controllers/field/field_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/field/field_model.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  String _formatHarga(int harga) {
    if (harga >= 1000000) {
      return '${(harga / 1000000).toStringAsFixed(harga % 1000000 == 0 ? 0 : 1)}jt';
    } else if (harga >= 1000) {
      return '${(harga / 1000).toStringAsFixed(harga % 1000 == 0 ? 0 : 1)}k';
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(harga);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);
    final allFieldsAsync = ref.watch(fieldsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Lapangan Favorit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: user == null
          ? _buildLoginPrompt(context)
          : favoriteIdsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B6B3A)),
              ),
              error: (e, _) => Center(
                child: Text('Terjadi kesalahan: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF718096))),
              ),
              data: (favoriteIds) {
                if (favoriteIds.isEmpty) {
                  return _buildEmptyState();
                }

                return allFieldsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B6B3A)),
                  ),
                  error: (e, _) => Center(
                    child: Text('Gagal memuat lapangan: $e',
                        textAlign: TextAlign.center),
                  ),
                  data: (allFields) {
                    final favoriteFields = allFields
                        .where((f) => favoriteIds.contains(f.id))
                        .toList();

                    if (favoriteFields.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favoriteFields.length,
                      itemBuilder: (context, index) {
                        return _FavoriteFieldCard(
                          field: favoriteFields[index],
                          formatHarga: _formatHarga,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Login untuk melihat favorit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan login terlebih dahulu\nuntuk menyimpan lapangan favorit.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
              ),
              child: const Icon(Icons.favorite_border, size: 48, color: Color(0xFF1B6B3A)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada lapangan favorit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan lapangan favoritmu\ndengan menekan ikon â¤ï¸ di halaman detail.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteFieldCard extends ConsumerWidget {
  final FieldModel field;
  final String Function(int) formatHarga;

  const _FavoriteFieldCard({required this.field, required this.formatHarga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/field-detail', arguments: field);
          },
          child: Row(
            children: [
              // Gambar lapangan
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: field.fotoUtama.isNotEmpty
                      ? Image.network(
                          field.fotoUtama,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE8F5EC),
                            child: const Center(
                              child: Icon(Icons.sports_soccer, size: 32, color: Color(0xFF1B6B3A)),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE8F5EC),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 32, color: Color(0xFF1B6B3A)),
                          ),
                        ),
                ),
              ),
              // Info lapangan
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              field.kategori.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B6B3A),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Tombol hapus favorit
                          GestureDetector(
                            onTap: () {
                              final user = ref.read(authStateProvider).value;
                              if (user != null) {
                                ref.read(favoriteServiceProvider).removeFavorite(user.uid, field.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${field.nama} dihapus dari favorit'),
                                    backgroundColor: const Color(0xFF1B6B3A),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        field.nama,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF718096)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              field.alamat,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                field.ratingAvg.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                              ),
                              Text(
                                ' (${field.totalUlasan})',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                              ),
                            ],
                          ),
                          Text(
                            'Rp ${formatHarga(field.hargaPerJam)}/jam',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B6B3A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
