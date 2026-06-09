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
    'Tenis'
  ];

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(sortedFieldsWithDistanceProvider);
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
              expandedHeight: MediaQuery.of(context).padding.top + 150.0,
              collapsedHeight: MediaQuery.of(context).padding.top + 76.0,
              user: user,
              avatarUrl: avatarUrl,
              hasAvatar: hasAvatar,
              unreadCount: ref.watch(unreadNotificationsCountProvider),
              onSearchTap: () => Navigator.pushNamed(context, '/search'),
              onNotificationTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationPage())),
              onAvatarTap: () {
                if (hasAvatar) {
                  _showFullScreenPhoto(context, avatarUrl);
                } else {
                  Navigator.pushNamed(context, '/customer-profile');
                }
              },
            ),
          ),

          // Categories - KEMBALI SEPERTI ASLI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Kategori',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
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
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4))
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(category,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14)),
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

          // Title - KEMBALI SEPERTI ASLI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory == 'Semua'
                        ? 'Rekomendasi Lapangan'
                        : 'Hasil Pencarian',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),

          // List Lapangan (HANYA INI YANG MENGGUNAKAN GRID)
          fieldsAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShimmerLoading.card(height: 200),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
                child: Center(
                    child: Text('Terjadi kesalahan:\n$e',
                        textAlign: TextAlign.center))),
            data: (fieldsWithDistance) {
              final filtered = fieldsWithDistance.where((fwd) {
                final matchCat = _selectedCategory == 'Semua' ||
                    fwd.field.kategori.toLowerCase().trim() ==
                        _selectedCategory.toLowerCase().trim();
                return matchCat;
              }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                      child: Text('Tidak ada lapangan yang sesuai.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16))),
                );
              }

              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final fwd = filtered[index];
                      return _FieldCard(
                          field: fwd.field,
                          distanceInMeters: fwd.distanceInMeters);
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

// --- Custom Header Delegate ---
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double fadeEnd = expandedHeight - collapsedHeight - 10.0;
    double opacity = 1.0 - (shrinkOffset / fadeEnd);
    opacity = opacity.clamp(0.0, 1.0);

    // Default location string based on the user's city or a fallback
    final locationText = (user?.city != null && user!.city!.isNotEmpty)
        ? user!.city!
        : 'Malang, Jawa Timur';

    final rawName = user?.nama.trim() ?? '';
    final greetingName =
        rawName.isNotEmpty ? rawName.split(RegExp(r'\s+')).first : 'Sobat';

    // Initial for avatar
    final initial = greetingName.isNotEmpty
        ? greetingName.substring(0, 1).toUpperCase()
        : 'S';

    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
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
                          'Halo, $greetingName',
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: Badge(
                            isLabelVisible: unreadCount > 0,
                            label: Text(unreadCount.toString()),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.notifications_none_rounded,
                                color: AppColors.textDark),
                          ),
                          onPressed: onNotificationTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary,
                          backgroundImage:
                              hasAvatar ? NetworkImage(avatarUrl!) : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  initial,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F7),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: onSearchTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            color: Color(0xFF8C98A8), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cari lapangan, lokasi, atau olahraga...',
                            style: TextStyle(
                                color: const Color(0xFF8C98A8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

// --- Field Card Widget (Grid Version) ---
class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final double? distanceInMeters;

  const _FieldCard({required this.field, this.distanceInMeters});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
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
                    height: 110,
                    width: double.infinity,
                    errorWidget: Container(
                      height: 110,
                      color: AppColors.primaryLight,
                      child: const Center(
                          child: Icon(Icons.stadium_outlined,
                              size: 40, color: AppColors.primary)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(field.kategori.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Icon(
                                  field.tipeLapangan == 'Indoor'
                                      ? Icons.roofing
                                      : Icons.wb_sunny_outlined,
                                  size: 10,
                                  color: Colors.white),
                              const SizedBox(width: 2),
                              Text(field.tipeLapangan.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (field.namaVenue.isNotEmpty) ...[
                        Text(
                          field.namaVenue.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(field.nama,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(
                          'Rp ${CurrencyFormatter.formatShort(field.hargaPerJam)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const Text('/ jam',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                              distanceInMeters != null
                                  ? Icons.directions_run
                                  : Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              distanceInMeters != null
                                  ? (distanceInMeters! > 1000
                                      ? '${(distanceInMeters! / 1000).toStringAsFixed(1)} km'
                                      : '${distanceInMeters!.toStringAsFixed(0)} m')
                                  : field.alamat,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 12),
                          Text(field.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
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
