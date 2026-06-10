import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/controllers/field/field_controller.dart';
// REFAKTOR: import shared constants & formatter
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';
import 'package:lapangku/standards/widgets/shimmer_loading.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';

class CustomerSearchPage extends ConsumerStatefulWidget {
  const CustomerSearchPage({super.key});

  @override
  ConsumerState<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends ConsumerState<CustomerSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedTipe = 'Semua'; // Semua / Indoor / Outdoor
  String _sortBy = 'Terdekat';

  // Advanced Filter & Sorting state
  Timer? _debounce;
  final List<String> _selectedFacilities = [];
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  final List<String> _availableFacilities = [
    'Shower', 'Toilet', 
    'Area Parkir', 'Kantin', 'Mushola', 'Gratis Bola'
  ];

  final List<String> _categories = [
    'Semua',
    'Futsal',
    'Mini Soccer',
    'Bulu Tangkis',
    'Basket',
    'Voli'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return; // Izin ditolak
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return; // Izin ditolak permanen
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aktifkan Lokasi'),
          content: const Text(
              'Akses GPS (Lokasi) belum aktif. Untuk menggunakan fitur "Urutkan Berdasarkan Terdekat", mohon aktifkan GPS perangkat Anda.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Urutkan Berdasarkan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Terdekat',
                        'Termurah',
                        'Harga Tertinggi',
                        'Rating Tertinggi'
                      ].map((sort) {
                        final isSelected = _sortBy == sort;
                        return ChoiceChip(
                          label: Text(sort),
                          selected: isSelected,
                          // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            if (sort == 'Terdekat') {
                              if (_isLoadingLocation) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Sedang mendeteksi lokasi, mohon tunggu...')),
                                );
                                return;
                              }
                              if (_currentPosition == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Akses GPS diperlukan untuk fitur ini.')),
                                );
                                _showLocationServiceDialog();
                                return;
                              }
                            }
                            setModalState(() => _sortBy = sort);
                            setState(() => _sortBy = sort);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Kategori Lapangan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            setModalState(() => _selectedCategory = cat);
                            setState(() => _selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tipe Lapangan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Semua', 'Indoor', 'Outdoor'].map((tipe) {
                        final isSelected = _selectedTipe == tipe;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tipe != 'Semua') ...[
                                Icon(
                                  tipe == 'Indoor'
                                      ? Icons.roofing
                                      : Icons.wb_sunny_outlined,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(tipe),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            setModalState(() => _selectedTipe = tipe);
                            setState(() => _selectedTipe = tipe);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Fasilitas',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableFacilities.map((facility) {
                        final isSelected =
                            _selectedFacilities.contains(facility);
                        return FilterChip(
                          label: Text(facility),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedFacilities.add(facility);
                              } else {
                                _selectedFacilities.remove(facility);
                              }
                            });
                            setState(() {});
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
                          // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Terapkan Filter',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
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
      // REFAKTOR: sebelumnya Color(0xFFF4F6F9)
      backgroundColor: AppColors.backgroundPage,
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
          // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    setState(() {
                      _searchQuery = val;
                    });
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari Lapangan...',
                  // REFAKTOR: sebelumnya Color(0xFF718096)
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textSecondary, size: 18),
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
                // REFAKTOR: sebelumnya Color(0xFF2D3748)
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                const Icon(Icons.tune, color: AppColors.primary),
                if (_selectedCategory != 'Semua' ||
                    _selectedTipe != 'Semua' ||
                    _sortBy != 'Terdekat' ||
                    _selectedFacilities.isNotEmpty)
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
          // REFAKTOR: sebelumnya Color(0xFF1B6B3A) dan Color(0xFF718096)
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
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
          // REFAKTOR: sebelumnya Color(0xFF2D3748)
          const Text(
            'Urutkan:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
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
        if (label == 'Terdekat') {
          if (_isLoadingLocation) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Sedang mendeteksi lokasi, mohon tunggu...')),
            );
            return;
          }
          if (_currentPosition == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Akses GPS diperlukan untuk fitur ini.')),
            );
            _showLocationServiceDialog();
            return;
          }
        }
        setState(() {
          _sortBy = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // REFAKTOR: sebelumnya Color(0xFF1B6B3A) dan Color(0xFF718096)
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AsyncValue<List<FieldModel>> fieldsAsync) {
    return fieldsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => ShimmerLoading.listTile(),
      ),
      error: (e, _) => Center(child: Text('Terjadi kesalahan:\n$e')),
      data: (fields) {
        final filtered = fields.where((f) {
          final matchQuery = _searchQuery.isEmpty ||
              f.nama
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase().trim()) ||
              f.namaVenue
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase().trim()) ||
              f.alamat
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase().trim());

          final matchCategory = _selectedCategory == 'Semua' ||
              f.kategori.toLowerCase() == _selectedCategory.toLowerCase();

          final matchTipe = _selectedTipe == 'Semua' ||
              f.tipeLapangan.toLowerCase() == _selectedTipe.toLowerCase();

          final matchFacilities = _selectedFacilities.isEmpty ||
              _selectedFacilities.every((facility) => f.fasilitas.any(
                  (fItem) => fItem.toLowerCase() == facility.toLowerCase()));

          return matchQuery && matchCategory && matchTipe && matchFacilities;
        }).toList();

        // Hitung jarak SEKALI ke Map — dipakai untuk sorting DAN render card.
        // Menghindari pemanggilan Geolocator.distanceBetween() 2x per lapangan.
        final Map<String, double> distances = {};
        if (_currentPosition != null) {
          for (final f in filtered) {
            distances[f.id] = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              f.latitude,
              f.longitude,
            );
          }
        }

        if (_sortBy == 'Termurah') {
          filtered.sort((a, b) => a.hargaPerJam.compareTo(b.hargaPerJam));
        } else if (_sortBy == 'Harga Tertinggi') {
          filtered.sort((a, b) => b.hargaPerJam.compareTo(a.hargaPerJam));
        } else if (_sortBy == 'Rating Tertinggi') {
          filtered.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
        } else if (_sortBy == 'Terdekat' && distances.isNotEmpty) {
          filtered.sort(
              (a, b) => (distances[a.id] ?? 0).compareTo(distances[b.id] ?? 0));
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
                  // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final field = filtered[index];
                    return _HorizontalFieldCard(
                      field: field,
                      distanceInMeters: distances[field.id],
                    );
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
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'Lapangan tidak ditemukan',
      subtitle:
          'Coba ubah filter atau gunakan kata kunci\nlain untuk hasil yang lebih luas.',
      actionButton: SizedBox(
        width: 200,
        height: 45,
        child: OutlinedButton(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _selectedCategory = 'Semua';
              _selectedTipe = 'Semua';
              _sortBy = 'Terdekat';
              _selectedFacilities.clear();
            });
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Reset Filter',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _HorizontalFieldCard extends StatelessWidget {
  final FieldModel field;
  final double? distanceInMeters;

  const _HorizontalFieldCard({required this.field, this.distanceInMeters});

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            CachedImageWidget(
              imageUrl: field.fotoUtama,
              width: 100,
              height: 100,
              borderRadius: 12,
              errorWidget: _buildImagePlaceholder(),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (field.namaVenue.isNotEmpty) ...[
                              Text(
                                field.namaVenue.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              field.nama,
                              // REFAKTOR: sebelumnya Color(0xFF2D3748)
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              // REFAKTOR: sebelumnya Color(0xFFE8F5EC) dan Color(0xFF1B6B3A)
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              field.kategori.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: field.tipeLapangan == 'Indoor'
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  field.tipeLapangan == 'Indoor'
                                      ? Icons.roofing
                                      : Icons.wb_sunny_outlined,
                                  size: 8,
                                  color: field.tipeLapangan == 'Indoor'
                                      ? const Color(0xFF4338CA)
                                      : const Color(0xFFEA580C),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  field.tipeLapangan.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: field.tipeLapangan == 'Indoor'
                                        ? const Color(0xFF4338CA)
                                        : const Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // REFAKTOR: sebelumnya Color(0xFF718096)
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          distanceInMeters != null
                              ? '${field.alamat.split(',').first} • ${(distanceInMeters! / 1000).toStringAsFixed(1)} km'
                              : field.alamat.split(',').first,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
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
                        // REFAKTOR: sebelumnya Color(0xFF2D3748)
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                      Text(
                        ' (${field.totalUlasan} ulasan)',
                        // REFAKTOR: sebelumnya Color(0xFF718096)
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                  const Text('TERSEDIA',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            // REFAKTOR: sebelumnya _formatHarga() local method
                            CurrencyFormatter.format(field.hargaPerJam),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary),
                          ),
                          // REFAKTOR: sebelumnya Color(0xFF718096)
                          const Text(
                            '/jam',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                          border:
                              Border.all(color: AppColors.primary, width: 1.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Pesan',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 14, color: AppColors.primary),
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
      // REFAKTOR: sebelumnya Color(0xFFE8F5EC) dan Color(0xFF1B6B3A)
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.stadium_outlined, size: 30, color: AppColors.primary),
      ),
    );
  }
}
