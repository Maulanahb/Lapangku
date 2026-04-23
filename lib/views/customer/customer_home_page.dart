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
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Futsal',
    'Mini Soccer',
    'Bulu Tangkis',
    'Basket',
    'Voli'
  ];

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsProvider);
    final user = ref.watch(authProvider).user;

    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1B6B3A),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF114B27), Color(0xFF1B6B3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${user?.nama ?? 'Sobat'} 👋',
                                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Cari Lapangan Favoritmu!',
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white.withValues(alpha: 0.24),
                                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                                  child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Nama lapangan atau lokasi...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF1B6B3A)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1B6B3A) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? const Color(0xFF1B6B3A) : Colors.grey.shade300),
                              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1B6B3A).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                            ),
                            child: Center(
                              child: Text(category, style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF718096),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                _searchQuery.isEmpty && _selectedCategory == 'Semua' ? 'Rekomendasi Lapangan' : 'Hasil Pencarian',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
            ),
          ),

          // List Lapangan
          fieldsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A)))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan:\n$e', textAlign: TextAlign.center))),
            data: (fields) {
              final filtered = fields.where((f) {
                final matchQuery = f.nama.toLowerCase().contains(_searchQuery.toLowerCase().trim()) ||
                    f.alamat.toLowerCase().contains(_searchQuery.toLowerCase().trim());
                final matchCat = _selectedCategory == 'Semua' ||
                    f.kategori.toLowerCase().trim() == _selectedCategory.toLowerCase().trim();
                return matchQuery && matchCat;
              }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Tidak ada lapangan yang sesuai.', style: TextStyle(color: Color(0xFF718096), fontSize: 16))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _FieldCard(field: filtered[index]),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FieldModel field;

  const _FieldCard({required this.field});

  String _formatHarga(int harga) {
    if (harga >= 1000000) {
      return '${(harga / 1000000).toStringAsFixed(harga % 1000000 == 0 ? 0 : 1)}jt';
    } else if (harga >= 1000) {
      return '${(harga / 1000).toStringAsFixed(harga % 1000 == 0 ? 0 : 1)}k';
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(harga);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/field-detail', arguments: field);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  field.fotoUtama.isNotEmpty
                      ? Image.network(field.fotoUtama, height: 180, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 180, color: const Color(0xFFE8F5EC),
                            child: const Center(child: Icon(Icons.sports_soccer, size: 56, color: Color(0xFF1B6B3A)))))
                      : Container(height: 180, color: const Color(0xFFE8F5EC),
                          child: const Center(child: Icon(Icons.image_not_supported, size: 56, color: Color(0xFF1B6B3A)))),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(field.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                        Text(' (${field.totalUlasan})', style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
                      ]),
                    ),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1B6B3A), borderRadius: BorderRadius.circular(8)),
                      child: Text(field.kategori.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(field.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Rp ${_formatHarga(field.hargaPerJam)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
                        const Text('/ jam', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
                      ]),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF718096)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(field.alamat, style: const TextStyle(fontSize: 13, color: Color(0xFF718096)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    if (field.fasilitas.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: field.fasilitas.take(4).map((f) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                            child: Text(f, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
                          )).toList(),
                        ),
                      ),
                    ],
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
