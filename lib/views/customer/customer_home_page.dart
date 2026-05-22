import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/controllers/field/field_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';
import 'package:lapangku/standards/widgets/shimmer_loading.dart';
import 'package:lapangku/controllers/notification/notification_controller.dart';
import 'package:lapangku/views/customer/notification_page.dart';
import 'package:geolocator/geolocator.dart';

class CustomerHomePage extends ConsumerStatefulWidget {
  const CustomerHomePage({super.key});

  @override
  ConsumerState<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends ConsumerState<CustomerHomePage> {
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
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      body: CustomScrollView(
        slivers: [
          // Custom Elegant Header (Greeting + Sticky Search Bar)
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              expandedHeight: 200.0,
              collapsedHeight: MediaQuery.of(context).padding.top + 76.0,
              user: user,
              avatarUrl: avatarUrl,
              hasAvatar: hasAvatar,
              unreadCount: ref.watch(unreadNotificationsCountProvider),
              onSearchTap: () => Navigator.pushNamed(context, '/search'),
              onNotificationTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
              onAvatarTap: () {
                if (hasAvatar) {
                  _showFullScreenPhoto(context, avatarUrl!);
                } else {
                  Navigator.pushNamed(context, '/customer-profile');
                }
              },
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
                    child: Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                              boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                            ),
                            child: Center(
                              child: Text(category, style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory == 'Semua' ? 'Rekomendasi Lapangan' : 'Hasil Pencarian',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  if (user?.alamatLatLng == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Isi alamat di Informasi Pribadi untuk melihat lapangan terdekat',
                              style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/customer-profile');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Isi Sekarang', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // List Lapangan
          fieldsAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShimmerLoading.card(height: 280),
                  childCount: 3,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan:\n$e', textAlign: TextAlign.center))),
            data: (fields) {
              final filtered = fields.where((f) {
                final matchCat = _selectedCategory == 'Semua' ||
                    f.kategori.toLowerCase().trim() == _selectedCategory.toLowerCase().trim();
                return matchCat;
              }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Tidak ada lapangan yang sesuai.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))),
                );
              }

              if (user?.alamatLatLng != null) {
                filtered.sort((a, b) {
                  final distA = Geolocator.distanceBetween(
                    user!.alamatLatLng!.latitude,
                    user.alamatLatLng!.longitude,
                    a.latitude,
                    a.longitude,
                  );
                  final distB = Geolocator.distanceBetween(
                    user.alamatLatLng!.latitude,
                    user.alamatLatLng!.longitude,
                    b.latitude,
                    b.longitude,
                  );
                  return distA.compareTo(distB);
                });
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final field = filtered[index];
                      double? distance;
                      if (user?.alamatLatLng != null) {
                        distance = Geolocator.distanceBetween(
                          user!.alamatLatLng!.latitude,
                          user.alamatLatLng!.longitude,
                          field.latitude,
                          field.longitude,
                        );
                      }
                      return _FieldCard(field: field, distanceInMeters: distance);
                    },
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

  void _showFullScreenPhoto(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: CachedImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Header Delegate ─────────────────────────────────────────────
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final UserModel? user;
  final String? avatarUrl;
  final bool hasAvatar;
  final int unreadCount;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;

  _HeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.user,
    required this.avatarUrl,
    required this.hasAvatar,
    required this.unreadCount,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.onAvatarTap,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return user != oldDelegate.user ||
        avatarUrl != oldDelegate.avatarUrl ||
        unreadCount != oldDelegate.unreadCount ||
        hasAvatar != oldDelegate.hasAvatar ||
        expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate fade-out opacity for greeting section
    final double fadeEnd = expandedHeight - collapsedHeight - 20.0;
    double opacity = 1.0 - (shrinkOffset / fadeEnd);
    opacity = opacity.clamp(0.0, 1.0);

    return Container(
      color: AppColors.primary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Greeting Text and Avatar (Fades out on scroll)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 24,
            right: 24,
            child: Opacity(
              opacity: opacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Text('Cari Lapangan\nFavoritmu!',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: IconButton(
                          icon: Badge(
                            isLabelVisible: unreadCount > 0,
                            label: Text(unreadCount.toString()),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                          ),
                          onPressed: onNotificationTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.24),
                          backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                          child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Search Bar (always visible at bottom)
          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSearchTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Nama lapangan atau lokasi...',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field Card Widget ──────────────────────────────────────────────────
class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final double? distanceInMeters;

  const _FieldCard({required this.field, this.distanceInMeters});

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
                  CachedImageWidget(
                    imageUrl: field.fotoUtama,
                    height: 180,
                    width: double.infinity,
                    errorWidget: Container(
                      height: 180,
                      color: AppColors.primaryLight,
                      child: const Center(child: Icon(Icons.stadium_outlined, size: 56, color: AppColors.primary)),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(field.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Text(' (${field.totalUlasan})', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: Text(field.kategori.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary, 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            children: [
                              Icon(
                                field.tipeLapangan == 'Indoor' ? Icons.roofing : Icons.wb_sunny_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                field.tipeLapangan.toUpperCase(), 
                                style: const TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white, 
                                  letterSpacing: 0.5
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
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
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(field.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Rp ${CurrencyFormatter.formatShort(field.hargaPerJam)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const Text('/ jam', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(field.alamat, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    if (distanceInMeters != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.directions_run, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          distanceInMeters! > 1000 
                              ? '${(distanceInMeters! / 1000).toStringAsFixed(1)} km dari lokasi Anda'
                              : '${distanceInMeters!.toStringAsFixed(0)} m dari lokasi Anda',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ],
                    if (field.fasilitas.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: field.fasilitas.take(4).map((f) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.backgroundChip, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                            child: Text(f, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
