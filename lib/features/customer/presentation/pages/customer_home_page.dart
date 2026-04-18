import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../field/domain/entities/field_entity.dart';
import '../../../field/presentation/providers/field_provider.dart';

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo 👋',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
            Text(
              'Cari lapangan favoritmu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
      body: fieldsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1B6B3A),
          ),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
        data: (fields) => fields.isEmpty
            ? const Center(
                child: Text('Belum ada lapangan tersedia'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  return _FieldCard(field: fields[index]);
                },
              ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FieldEntity field;

  const _FieldCard({required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Image.network(
              field.fotoUtama,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: const Color(0xFFE8F5EC),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 48,
                  color: Color(0xFF1B6B3A),
                ),
              ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + kategori
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        field.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        field.kategori,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B6B3A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Alamat
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF718096),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        field.alamat,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rating + harga
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${field.ratingAvg} (${field.totalUlasan})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rp ${field.hargaPerJam ~/ 1000}k/jam',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B6B3A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}