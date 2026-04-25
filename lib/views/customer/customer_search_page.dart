import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/controllers/field/field_controller.dart';

class CustomerSearchPage extends ConsumerStatefulWidget {
  const CustomerSearchPage({super.key});

  @override
  ConsumerState<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends ConsumerState<CustomerSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _sortBy = 'Terdekat';

  final List<String> _categories = [
    'Semua',
    'Futsal',
    'Mini Soccer',
    'Bulu Tangkis',
    'Basket',
    'Voli'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Urutkan Berdasarkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Terdekat', 'Termurah', 'Harga Tertinggi', 'Rating Tertinggi'].map((sort) {
                      final isSelected = _sortBy == sort;
                      return ChoiceChip(
                        label: Text(sort),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B6B3A),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          setModalState(() => _sortBy = sort);
                          setState(() => _sortBy = sort);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Kategori Lapangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B6B3A),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          setModalState(() => _selectedCategory = cat);
                          setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B3A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            _buildSortBy(),
            Expanded(
              child: _buildResults(fieldsAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B6B3A)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari Lapangan...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF718096), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF718096), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune, color: Color(0xFF1B6B3A)),
                if (_selectedCategory != 'Semua' || _sortBy != 'Terdekat')
                  Positioned(
                    top: 0,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(category, isSelected, () {
              setState(() {
                _selectedCategory = category;
              });
            }),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B6B3A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF1B6B3A) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF718096),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSortBy() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Urutkan:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(width: 12),
          _buildSortChip('Terdekat'),
          const SizedBox(width: 8),
          _buildSortChip('Termurah'),
          const SizedBox(width: 8),
          _buildSortChip('Rating Tertinggi'),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label) {
    bool isSelected = _sortBy == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B6B3A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF1B6B3A) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF718096),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AsyncValue<List<FieldModel>> fieldsAsync) {
    return fieldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
      error: (e, _) => Center(child: Text('Terjadi kesalahan:\n$e')),
      data: (fields) {
        final filtered = fields.where((f) {
          final matchQuery = _searchQuery.isEmpty || 
              f.nama.toLowerCase().contains(_searchQuery.toLowerCase().trim()) ||
              f.alamat.toLowerCase().contains(_searchQuery.toLowerCase().trim());
              
          final matchCategory = _selectedCategory == 'Semua' || 
              f.kategori.toLowerCase() == _selectedCategory.toLowerCase();

          return matchQuery && matchCategory;
        }).toList();

        if (_sortBy == 'Termurah') {
          filtered.sort((a, b) => a.hargaPerJam.compareTo(b.hargaPerJam));
        } else if (_sortBy == 'Harga Tertinggi') {
          filtered.sort((a, b) => b.hargaPerJam.compareTo(a.hargaPerJam));
        } else if (_sortBy == 'Rating Tertinggi') {
          filtered.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
        }

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '${filtered.length} lapangan ditemukan',
                  style: const TextStyle(color: Color(0xFF1B6B3A), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _HorizontalFieldCard(field: filtered[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Stack(
                children: [
                  Icon(Icons.search, size: 50, color: Color(0xFF718096)),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(Icons.close, size: 20, color: Color(0xFF718096)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lapangan tidak ditemukan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba ubah filter atau gunakan kata kunci\nlain untuk hasil yang lebih luas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF718096), fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 45,
            child: OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'Semua';
                  _sortBy = 'Terdekat';
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1B6B3A), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reset Filter', style: TextStyle(color: Color(0xFF1B6B3A), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalFieldCard extends StatelessWidget {
  final FieldModel field;

  const _HorizontalFieldCard({required this.field});

  String _formatHarga(int harga) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(harga);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/field-detail', arguments: field);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: field.fotoUtama.isNotEmpty
                  ? Image.network(
                      field.fotoUtama,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          field.nama,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          field.kategori.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF718096)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${field.alamat.split(',').first} • 1.2 km', // Mock distance
                          style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        field.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                      Text(
                        ' (${field.totalUlasan} ulasan)',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('TERSEDIA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A), letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatHarga(field.hargaPerJam),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1B6B3A)),
                          ),
                          const Text(
                            '/jam',
                            style: TextStyle(fontSize: 10, color: Color(0xFF718096), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1B6B3A), width: 1.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Pesan',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A)),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14, color: Color(0xFF1B6B3A)),
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
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: const Color(0xFFE8F5EC),
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 30, color: Color(0xFF1B6B3A)),
      ),
    );
  }
}
