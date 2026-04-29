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

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchFilter(),
          Expanded(
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kelola Pengguna',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showUserForm(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _primary),
                onPressed: () => ref.read(allUsersProvider.notifier).load(),
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
              children: ['semua', 'customer', 'owner', 'admin'].map((role) {
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: roleColor.withOpacity(0.15),
            child: Text(
              initials,
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF718096)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _roleLabel(role),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (statusVerifikasi.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _verifikasiColor(statusVerifikasi)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _verifikasiLabel(statusVerifikasi),
                          style: TextStyle(
                            color: _verifikasiColor(statusVerifikasi),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
              if (role.toLowerCase() == 'owner' && statusVerifikasi == 'menunggu') ...[
                Row(
                  children: [
                    _actionBtn(Icons.check, Colors.green, 'Setujui', () {
                      _updateVerifikasi(uid, name, 'aktif');
                    }),
                    const SizedBox(width: 6),
                    _actionBtn(Icons.close, Colors.red, 'Tolak', () {
                      _updateVerifikasi(uid, name, 'ditolak');
                    }),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Row(
                children: [
                  _actionBtn(Icons.edit, Colors.blue, 'Edit', () {
                    _showUserForm(user);
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.delete, Colors.red, 'Hapus', () {
                    _deleteUser(uid, name);
                  }),
                ],
              ),
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
        title: Text(status == 'aktif' ? 'Verifikasi Owner' : 'Tolak Owner'),
        content: Text(
          status == 'aktif'
              ? 'Verifikasi akun owner "$name"?'
              : 'Tolak akun owner "$name"?',
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
              ? 'Owner berhasil diverifikasi'
              : 'Owner berhasil ditolak'),
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

  void _showUserForm(Map<String, dynamic>? user) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?['nama'] ?? user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final phoneController = TextEditingController(text: user?['phone'] ?? '');
    String selectedRole = user?['role'] ?? 'customer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField('Nama', nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField('Email', emailController, Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('Nomor Telepon', phoneController, Icons.phone_outlined),
                    const SizedBox(height: 16),
                    const Text('Role', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF4A5568))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          items: ['customer', 'owner', 'admin'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(_roleLabel(value)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setStateModal(() {
                              if (newValue != null) selectedRole = newValue;
                            });
                          },
                        ),
                      ),
                    ),
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
                            'phone': phoneController.text.trim(),
                            'role': selectedRole,
                          };

                          Navigator.pop(context);

                          if (isEdit) {
                            await ref.read(allUsersProvider.notifier).updateUser(user!['uid'], data);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pengguna berhasil diperbarui'), backgroundColor: _primary),
                              );
                            }
                          } else {
                            await ref.read(allUsersProvider.notifier).addUser(data);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pengguna berhasil ditambahkan'), backgroundColor: _primary),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Pengguna', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
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
      case 'owner':
      case 'mitra':
        return 'Owner';
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
      case 'owner':
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
