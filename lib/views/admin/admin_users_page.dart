import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  static const _primary = Color(0xFF1B6B3A);
  String _searchQuery = '';
  String _filterRole = 'semua';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
        _buildHeader(),
        _buildSearchFilter(),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async =>
                  ref.read(allUsersProvider.notifier).load(),
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: _primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (users) => _buildList(users),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Pengguna',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manajemen akun customer, mitra, dan admin.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.read(allUsersProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari pengguna...',
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFFADB5BD), size: 20),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['semua', 'customer', 'mitra', 'admin'].map((role) {
                final selected = _filterRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterRole = role),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? _primary : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(role),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF718096),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> users) {
    var filtered = users.where((u) {
      final name = (u['nama'] ?? u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      final matchSearch =
          name.contains(_searchQuery) || email.contains(_searchQuery);
      final matchRole = _filterRole == 'semua' || role == _filterRole;
      return matchSearch && matchRole;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pengguna ditemukan',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildUserCard(filtered[i]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = (user['nama'] ?? user['name'] ?? 'Tanpa Nama').toString();
    final email = (user['email'] ?? '-').toString();
    final role = (user['role'] ?? '-').toString();
    final statusVerifikasi =
        (user['statusVerifikasi'] ?? '').toString();
    final uid = (user['uid'] ?? '').toString();

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    final roleColor = _roleColor(role);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: roleColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: roleColor.withOpacity(0.1),
              child: Text(
                initials,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      email,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF718096), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _roleLabel(role).toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (statusVerifikasi.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _verifikasiColor(statusVerifikasi)
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusVerifikasi == 'aktif' ? Icons.verified_rounded : Icons.pending_rounded,
                              size: 10,
                              color: _verifikasiColor(statusVerifikasi),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _verifikasiLabel(statusVerifikasi).toUpperCase(),
                              style: TextStyle(
                                color: _verifikasiColor(statusVerifikasi),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (user['isActive'] == false) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block_flipped, size: 10, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'NONAKTIF',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (role.toLowerCase() == 'mitra' && statusVerifikasi == 'menunggu') ...[
                _actionBtn(Icons.check_circle_rounded, Colors.green, 'Setujui', () {
                  _updateVerifikasi(uid, name, 'aktif');
                }),
                const SizedBox(width: 8),
                _actionBtn(Icons.cancel_rounded, Colors.red, 'Tolak', () {
                  _updateVerifikasi(uid, name, 'ditolak');
                }),
                const SizedBox(width: 8),
              ],
              _actionBtn(Icons.edit_note_rounded, Colors.blue, 'Edit', () {
                _showUserForm(user);
              }),
              const SizedBox(width: 8),
              _actionBtn(
                (user['isActive'] ?? true) ? Icons.block_flipped : Icons.check_circle_outline,
                (user['isActive'] ?? true) ? Colors.orange : Colors.green,
                (user['isActive'] ?? true) ? 'Nonaktifkan' : 'Aktifkan',
                () {
                  _toggleActiveUser(uid, name, user['isActive'] ?? true);
                },
              ),
              const SizedBox(width: 8),
              _actionBtn(Icons.delete_sweep_rounded, Colors.redAccent, 'Hapus', () {
                _deleteUser(uid, name);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Future<void> _updateVerifikasi(String uid, String name, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(status == 'aktif' ? 'Verifikasi Mitra' : 'Tolak Mitra'),
        content: Text(
          status == 'aktif'
              ? 'Verifikasi akun Mitra "$name"?'
              : 'Tolak akun Mitra "$name"?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'aktif' ? _primary : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(status == 'aktif' ? 'Verifikasi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(allUsersProvider.notifier)
          .updateVerifikasi(uid, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'aktif'
              ? 'Mitra berhasil diverifikasi'
              : 'Mitra berhasil ditolak'),
          backgroundColor: status == 'aktif' ? _primary : Colors.red,
        ));
      }
    }
  }

  Future<void> _deleteUser(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengguna'),
        content: Text('Yakin ingin menghapus pengguna "$name"? Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(allUsersProvider.notifier).deleteUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil dihapus'),
            backgroundColor: _primary,
          ),
        );
      }
    }
  }

  Future<void> _toggleActiveUser(String uid, String name, bool currentActive) async {
    final action = currentActive ? 'menonaktifkan' : 'mengaktifkan';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${currentActive ? 'Nonaktifkan' : 'Aktifkan'} Pengguna'),
        content: Text('Yakin ingin $action pengguna "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(currentActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(allUsersProvider.notifier).updateUser(uid, {'isActive': !currentActive});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengguna berhasil ${currentActive ? 'dinonaktifkan' : 'diaktifkan'}'),
            backgroundColor: _primary,
          ),
        );
      }
    }
  }

  void _showUserForm(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['nama'] ?? user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final isAdmin = (user['role'] ?? '').toString().toLowerCase() == 'admin';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Pengguna',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Nama', nameController, Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField('Email', emailController, Icons.email_outlined),
                      if (!isAdmin) ...[
                        const SizedBox(height: 16),
                        _buildTextField('Nomor Telepon', phoneController, Icons.phone_outlined),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty || emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama dan Email harus diisi')),
                              );
                              return;
                            }
                            
                            final data = {
                              'nama': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              if (!isAdmin) 'phone': phoneController.text.trim(),
                            };

                            Navigator.pop(context);

                            await ref.read(allUsersProvider.notifier).updateUser(user['uid'], data);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pengguna berhasil diperbarui'), backgroundColor: _primary),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF4A5568))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFADB5BD)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String r) {
    switch (r.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'Mitra':
      case 'mitra':
        return 'Mitra';
      case 'admin':
        return 'Admin';
      case 'semua':
        return 'Semua';
      default:
        return r;
    }
  }

  Color _roleColor(String r) {
    switch (r.toLowerCase()) {
      case 'customer':
        return const Color(0xFF2196F3);
      case 'Mitra':
      case 'mitra':
        return const Color(0xFF9C27B0);
      case 'admin':
        return const Color(0xFF1B6B3A);
      default:
        return Colors.grey;
    }
  }

  String _verifikasiLabel(String s) {
    switch (s) {
      case 'aktif':
        return 'Terverifikasi';
      case 'ditolak':
        return 'Ditolak';
      case 'menunggu':
        return 'Menunggu';
      default:
        return s;
    }
  }

  Color _verifikasiColor(String s) {
    switch (s) {
      case 'aktif':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return const Color(0xFFFFB74D);
    }
  }
}
