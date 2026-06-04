import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/services/firebase_storage_service.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  final FocusNode _phoneFocusNode = FocusNode();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _populateData(UserModel user) {
    if (!_isInitialized) {
      _nameController.text = user.nama;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _isInitialized = true;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingOverlay.show(context, message: 'Menyimpan perubahan...');

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // Tetap kirimkan data lama untuk kota, alamat, dan birthday agar tidak hilang/error di database
        await ref.read(authProvider.notifier).updateProfile(
              uid: user.uid,
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              gender: user.gender,
              city: user.city,
              address: user.address,
              birthday: user.birthday,
            );

        if (!mounted) return;
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      LoadingOverlay.dismiss(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Informasi Pribadi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Gagal Memuat Data',
          subtitle: err.toString(),
          actionButton: ElevatedButton(
            onPressed: () => ref.invalidate(authStateProvider),
            child: const Text('Coba Lagi'),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'Data tidak ditemukan',
              subtitle: 'Silakan login kembali.',
            );
          }
          _populateData(user);
          return _buildContent(context, user);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, user),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildSectionTitle('Informasi Dasar'),
                  _buildEditableField(
                    label: 'NAMA LENGKAP',
                    controller: _nameController,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  _buildEditableField(
                    label: 'EMAIL',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Email tidak boleh kosong';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v)) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  _buildEditableField(
                    label: 'NOMOR HP',
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    trailing: GestureDetector(
                      onTap: () => _phoneFocusNode.requestFocus(),
                      child: const Text(
                        'Ubah',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Nomor HP tidak boleh kosong';
                      if (v.length < 10) return 'Minimal 10 digit';
                      return null;
                    },
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final String initials = user.nama
        .trim()
        .split(' ')
        .map((l) => l[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage:
                    user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context, user),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.nama,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer LapangKu',
            style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola informasi akun pribadi kamu',
            style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery, user);
              },
            ),
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus Foto',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeletePhoto(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source, UserModel user) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        if (!mounted) return;
        LoadingOverlay.show(context, message: 'Mengunggah foto...');

        final String? imageUrl = await FirebaseStorageService.uploadImage(
            File(image.path),
            folder: 'avatars');

        if (imageUrl != null) {
          await ref
              .read(authProvider.notifier)
              .updateAvatar(user.uid, imageUrl);

          if (!mounted) return;
          LoadingOverlay.dismiss(context);

          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto: $e')),
        );
      }
    }
  }

  Future<void> _handleDeletePhoto(UserModel user) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Hapus Foto',
      message: 'Apakah Anda yakin ingin menghapus foto profil?',
      confirmText: 'Hapus',
      isDestructive: true,
    );

    if (confirm == true) {
      if (!mounted) return;
      LoadingOverlay.show(context, message: 'Menghapus foto...');

      try {
        await ref.read(authProvider.notifier).updateAvatar(user.uid, null);

        if (!mounted) return;
        LoadingOverlay.dismiss(context);

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil telah dihapus')),
        );
      } catch (e) {
        if (mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus foto: $e')),
          );
        }
      }
    }
  }



  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textHeading,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            focusNode: focusNode,
            style: const TextStyle(color: AppColors.textDark, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundField,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: trailing != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [trailing],
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }


}
