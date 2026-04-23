import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/controllers/field/field_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
  String _searchQuery = '';
  String _selectedCategory = 'Futsal'; // Default from mockup

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Hide default appbar, use custom header below
      ),
      body: CustomScrollView(
        slivers: [
          // Header: Search Bar & Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Row(
                    children: [
                      const Icon(Icons.arrow_back, color: Color(0xFF059669)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Light grey
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: const InputDecoration(
                              hintText: 'Futsal Malang', // From mockup
                              hintStyle: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                              suffixIcon: Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Stack(
                        children: [
                          const Icon(Icons.tune, color: Color(0xFF059669)),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Futsal', true, true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Malang', true, true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Harga', false, false, hasDropdown: true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rating', false, false, hasDropdown: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sort Options Row
                  Row(
                    children: [
                      const Text('Urutkan: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      const SizedBox(width: 8),
                      _buildSortChip('Terdekat', true),
                      const SizedBox(width: 8),
                      _buildSortChip('Termurah', false),
                      const SizedBox(width: 8),
                      _buildSortChip('Rating Tertinggi', false),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Field List
          fieldsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF059669)))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan:\n$e', textAlign: TextAlign.center))),
            data: (fields) {
              final filtered = fields.where((f) {
                final matchQuery = f.nama.toLowerCase().contains(_searchQuery.toLowerCase().trim()) ||
                    f.alamat.toLowerCase().contains(_searchQuery.toLowerCase().trim());
                // Dummy logic for 'Futsal Malang'
                return matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off, size: 48, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),
                        const Text('Lapangan tidak ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        const Text(
                          'Coba ubah filter atau gunakan kata kunci\nlain untuk hasil yang lebih luas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF059669)),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reset Filter', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          '${filtered.length} lapangan ditemukan',
                          style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );
                    }
                    return _FieldCard(field: filtered[index - 1]);
                  },
                  childCount: filtered.length + 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool hasClose, {bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF059669) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (hasClose) ...[
            const SizedBox(width: 4),
            Icon(Icons.close, size: 14, color: isSelected ? Colors.white70 : const Color(0xFF64748B)),
          ],
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          ]
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF059669) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FieldModel field;

  const _FieldCard({required this.field});

  String _formatHarga(int harga) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(harga);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/field-detail', arguments: field);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFE2E8F0),
                ),
                clipBehavior: Clip.antiAlias,
                child: field.fotoUtama.isNotEmpty
                    ? Image.network(field.fotoUtama, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.grey))
                    : const Icon(Icons.image, color: Colors.grey),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            field.nama,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6EE7B7), // Light green badge
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            field.kategori.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${field.alamat.split(',').first} • 1.2 km', // Mock distance
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          field.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          ' (${field.totalUlasan} ulasan)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('TERSEDIA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatHarga(field.hargaPerJam),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const Text(
                              '/jam',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1E293B)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Text('Pesan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 12, color: Color(0xFF1E293B)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
