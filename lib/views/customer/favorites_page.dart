import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/favorite/favorite_controller.dart';
import 'package:lapangku/controllers/field/field_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/services/firebase/favorite_service.dart';
// REFAKTOR: import shared components
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // REFAKTOR: hapus _formatHarga() lokal — gunakan CurrencyFormatter

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<FieldModel> fields) {
    setState(() {
      if (_selectedIds.length == fields.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(fields.map((f) => f.id));
      }
    });
  }

  Future<void> _deleteSelected(String userId) async {
    // REFAKTOR: sebelumnya showDialog AlertDialog manual
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Hapus Favorit?',
      message: 'Apakah Anda yakin ingin menghapus ${_selectedIds.length} lapangan dari favorit?',
      confirmText: 'Hapus',
      isDestructive: true,
    );
    if (confirm != true) return;

    final service = ref.read(favoriteServiceProvider);
    // REFAKTOR: sebelumnya showDialog loading manual — Color(0xFF1B6B3A)
    if (mounted) LoadingOverlay.show(context, message: 'Menghapus...');

    try {
      final futures = _selectedIds.map((id) => service.removeFavorite(userId, id));
      await Future.wait(futures);
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_selectedIds.length} lapangan dihapus dari favorit'),
          backgroundColor: AppColors.primary, // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
        ));
        setState(() { _isSelectionMode = false; _selectedIds.clear(); });
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);
    final allFieldsAsync = ref.watch(fieldsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage, // REFAKTOR: sebelumnya Color(0xFFF4F6F9)
      appBar: AppBar(
        title: const Text('Lapangan Favorit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary, // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        elevation: 0,
        actions: [
          if (user != null)
            favoriteIdsAsync.maybeWhen(
              data: (favoriteIds) {
                if (favoriteIds.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: _toggleSelectionMode,
                  child: Text(
                    _isSelectionMode ? 'Batal' : 'Pilih',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: user == null
          ? _buildLoginPrompt()
          : favoriteIdsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary))),
              data: (favoriteIds) {
                if (favoriteIds.isEmpty) return _buildEmptyState();
                return allFieldsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Gagal memuat lapangan: $e', textAlign: TextAlign.center)),
                  data: (allFields) {
                    final favoriteFields = allFields.where((f) => favoriteIds.contains(f.id)).toList();
                    if (favoriteFields.isEmpty) return _buildEmptyState();
                    return Column(children: [
                      if (_isSelectionMode)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(children: [
                            Checkbox(
                              value: _selectedIds.length == favoriteFields.length && favoriteFields.isNotEmpty,
                              onChanged: (_) => _selectAll(favoriteFields),
                              activeColor: AppColors.primary, // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                            ),
                            const Text('Pilih Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (_selectedIds.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _deleteSelected(user.uid),
                                icon: const Icon(Icons.delete, size: 18),
                                label: Text('Hapus (${_selectedIds.length})'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
                              ),
                          ]),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: favoriteFields.length,
                          itemBuilder: (context, index) {
                            final field = favoriteFields[index];
                            return _FavoriteFieldCard(
                              field: field,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(field.id),
                              onSelect: () => _toggleSelection(field.id),
                            );
                          },
                        ),
                      ),
                    ]);
                  },
                );
              },
            ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.login_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Login untuk melihat favorit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('Silakan login terlebih dahulu\nuntuk menyimpan lapangan favorit.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
      ),
    );
  }

  // REFAKTOR: sebelumnya Column + Container + Icon + Text inline — sekarang EmptyStateWidget
  Widget _buildEmptyState() => const EmptyStateWidget(
        icon: Icons.favorite_border,
        title: 'Belum ada lapangan favorit',
        subtitle: 'Tambahkan lapangan favoritmu\ndengan menekan ikon ❤️ di halaman detail.',
      );
}

// ────────────────────────────────────────────────────────────────────────────

class _FavoriteFieldCard extends ConsumerWidget {
  final FieldModel field;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelect;

  const _FavoriteFieldCard({
    required this.field,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.white, // REFAKTOR: sebelumnya Color(0xFFE8F5EC)
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null, // REFAKTOR
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSelectionMode) {
              onSelect();
            } else {
              Navigator.pushNamed(context, '/field-detail', arguments: field);
            }
          },
          child: Row(children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect(),
                  activeColor: AppColors.primary, // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSelectionMode ? 0 : 16),
                bottomLeft: Radius.circular(isSelectionMode ? 0 : 16),
              ),
              child: SizedBox(
                width: 100, height: 100,
                child: field.fotoUtama.isNotEmpty
                    ? Image.network(field.fotoUtama, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryLight, // REFAKTOR: Color(0xFFE8F5EC)
                          child: const Center(child: Icon(Icons.sports_soccer, size: 32, color: AppColors.primary)),
                        ))
                    : Container(
                        color: AppColors.primaryLight, // REFAKTOR: Color(0xFFE8F5EC)
                        child: const Center(child: Icon(Icons.image_not_supported, size: 32, color: AppColors.primary)),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySelected, // REFAKTOR: Color(0xFFD1FAE5)
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(field.kategori.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const Spacer(),
                    if (!isSelectionMode)
                      GestureDetector(
                        onTap: () {
                          final user = ref.read(authStateProvider).value;
                          if (user != null) {
                            ref.read(favoriteServiceProvider).removeFavorite(user.uid, field.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${field.nama} dihapus dari favorit'),
                              backgroundColor: AppColors.primary, // REFAKTOR: Color(0xFF1B6B3A)
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        },
                        child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  if (field.namaVenue.isNotEmpty) ...[
                    Text(field.namaVenue.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                  ],
                  Text(field.nama,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(child: Text(field.alamat,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(field.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text(' (${field.totalUlasan})',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ]),
                    Text(
                      // REFAKTOR: sebelumnya 'Rp ${formatHarga(field.hargaPerJam)}/jam' local method
                      '${CurrencyFormatter.format(field.hargaPerJam)}/jam',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
