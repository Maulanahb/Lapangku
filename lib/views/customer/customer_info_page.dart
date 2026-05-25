import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/customer/customer_info_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/services/firebase_storage_service.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';

class CustomerInfoPage extends ConsumerStatefulWidget {
  const CustomerInfoPage({super.key});

  @override
  ConsumerState<CustomerInfoPage> createState() => _CustomerInfoPageState();
}

class _CustomerInfoPageState extends ConsumerState<CustomerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  
  String? _selectedDate;
  String? _selectedGender;
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initData() {
    final userAsync = ref.read(authStateProvider);
    final user = userAsync.value;
    if (user != null && !_isInit) {
      _nameController.text = user.nama == 'User Tanpa Nama' ? '' : user.nama;
      _phoneController.text = user.phone ?? '';
      _cityController.text = user.city ?? '';
      _addressController.text = user.address ?? '';
      _selectedDate = user.birthday;
      _selectedGender = user.gender;
      _isInit = true;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_selectedDate != null && _selectedDate!.isNotEmpty) {
      try {
        initialDate = DateFormat('dd MMM yyyy').parse(_selectedDate!);
      } catch (e) {
        try {
          initialDate = DateFormat('yyyy-MM-dd').parse(_selectedDate!);
        } catch (_) {}
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    LoadingOverlay.show(context, message: 'Menyimpan profil...');

    try {
      final result = await ref.read(customerInfoControllerProvider).updateCustomerProfile(
        nama: _nameController.text,
        phone: _phoneController.text,
        birthday: _selectedDate,
        gender: _selectedGender,
        city: _cityController.text,
        address: _addressController.text,
      );

      if (mounted) {
        LoadingOverlay.dismiss(context);

        if (result.geocodingFailed) {
          // Profil tetap tersimpan, tapi geocoding gagal → tampilkan peringatan
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil disimpan, tapi gagal mendapatkan titik koordinat. Alamat tetap tersimpan.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan'), backgroundColor: Colors.green),
          );
        }

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'User Tanpa Nama') return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Informasi Pribadi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInit) {
        setState(() {
          _initData();
        });
      }
    });

    final progress = ref.read(customerInfoControllerProvider).calculateProgress(user);
    final fieldBackgroundColor = const Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Informasi Pribadi', 
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // HEADER PROFILE
              GestureDetector(
                onTap: () {
                  if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
                    _showFullScreenPhoto(context, user.avatarUrl!);
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? Text(
                              _getInitials(user.nama),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.nama == 'User Tanpa Nama' ? 'Pengguna' : user.nama,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHeading),
              ),
              const SizedBox(height: 4),
              const Text(
                'Customer LapangKu',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              const Text(
                'Kelola informasi akun pribadi kamu',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // PROFIL CARD (Progress Bar)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Profil Kamu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Lengkapi data pribadi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        color: Colors.lightGreenAccent,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // INFORMASI DASAR SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Dasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeading)),
                    const SizedBox(height: 16),

                    // NAMA LENGKAP
                    const Text('NAMA LENGKAP', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Minimal 3 karakter' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // EMAIL
                    const Text('EMAIL', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(user.email, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                    ),
                    const SizedBox(height: 16),

                    // NOMOR HP
                    const Text('NOMOR HP', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Tidak boleh kosong';
                                if (v.trim().length < 10) return 'Minimal 10 digit';
                                if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Hanya boleh berisi angka';
                                return null;
                              },
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Ubah', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TANGGAL LAHIR
                    const Text('TANGGAL LAHIR', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate ?? 'Pilih Tanggal Lahir',
                              style: TextStyle(fontSize: 14, color: _selectedDate == null ? Colors.grey : AppColors.textDark),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // INFORMASI TAMBAHAN SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeading)),
                    const SizedBox(height: 16),

                    // JENIS KELAMIN
                    const Text('JENIS KELAMIN', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: fieldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedGender = 'Laki-laki'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Laki-laki' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _selectedGender == 'Laki-laki' 
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Center(
                                  child: Text('Laki-laki', 
                                    style: TextStyle(
                                      color: _selectedGender == 'Laki-laki' ? AppColors.primaryDark : Colors.grey, 
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedGender = 'Perempuan'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Perempuan' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _selectedGender == 'Perempuan' 
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Center(
                                  child: Text('Perempuan', 
                                    style: TextStyle(
                                      color: _selectedGender == 'Perempuan' ? AppColors.primaryDark : Colors.grey, 
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KOTA
                    const Text('KOTA', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Malang, Jawa Timur',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none, 
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ALAMAT
                    const Text('ALAMAT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                      child: TextFormField(
                        controller: _addressController,
                        minLines: 2,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan alamat lengkap...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none, 
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // TOMBOL SIMPAN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  // ===== FOTO PROFIL: Upload, Hapus, Lihat Fullscreen =====

  void _showImageSourceActionSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Foto Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery, user);
              },
            ),
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                title: const Text('Lihat Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _showFullScreenPhoto(context, user.avatarUrl!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus Foto', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeletePhoto(user);
                },
              ),
            ],
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

        final String? imageUrl = await FirebaseStorageService.uploadImage(File(image.path), folder: 'avatars');

        if (imageUrl != null) {
          await ref.read(authProvider.notifier).updateAvatar(user.uid, imageUrl);

          if (!mounted) return;
          LoadingOverlay.dismiss(context);
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto: $e'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Foto profil telah dihapus'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus foto: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
