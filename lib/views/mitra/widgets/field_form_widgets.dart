import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:lapangku/standards/constants/app_colors.dart';

class MitraProfileDocumentPage extends ConsumerStatefulWidget {
  const MitraProfileDocumentPage({super.key});

  @override
  ConsumerState<MitraProfileDocumentPage> createState() =>
      _MitraProfileDocumentPageState();
}

class _MitraProfileDocumentPageState
    extends ConsumerState<MitraProfileDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _businessNameController;
  late TextEditingController _MitraNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankAccountNameController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(mitraProfileProvider).value;
    _businessNameController =
        TextEditingController(text: profileState?.businessName ?? '');
    _MitraNameController =
        TextEditingController(text: profileState?.MitraName ?? '');
    _emailController = TextEditingController(text: profileState?.email ?? '');
    _phoneController = TextEditingController(text: profileState?.phone ?? '');
    _addressController =
        TextEditingController(text: profileState?.alamat ?? '');
    _descriptionController =
        TextEditingController(text: profileState?.description ?? '');
    _bankNameController =
        TextEditingController(text: profileState?.bankName ?? '');
    _bankAccountController =
        TextEditingController(text: profileState?.bankAccount ?? '');
    _bankAccountNameController =
        TextEditingController(text: profileState?.bankAccountName ?? '');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _MitraNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  // ─── LOGIKA FUNGSI ───
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      await ref.read(mitraProfileProvider.notifier).updateProfile(
            businessName: _businessNameController.text.trim(),
            MitraName: _MitraNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            alamat: _addressController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      await ref.read(mitraProfileProvider.notifier).updateBankInfo(
            _bankNameController.text.trim(),
            _bankAccountController.text.trim(),
            _bankAccountNameController.text.trim(),
          );
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Profil berhasil diperbarui');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // LOGIKA BARU: Bottom Sheet Picker
  void _showLogoPicker(MitraProfileModel profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadLogo(ImageSource.camera);
                }),
            ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadLogo(ImageSource.gallery);
                }),
            if (profile.logoUrl != null && profile.logoUrl!.isNotEmpty)
              ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteLogo();
                  }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadLogo(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(mitraProfileProvider.notifier)
          .uploadLogo(File(picked.path));
      if (mounted) SnackbarHelper.showSuccess(context, 'Logo diperbarui');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLogo() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(mitraProfileProvider.notifier).deleteLogo();
      if (mounted) SnackbarHelper.showSuccess(context, 'Foto dihapus');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadDoc(String docType) async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(mitraProfileProvider.notifier)
          .uploadDocument(docType, File(picked.path));
      if (mounted) SnackbarHelper.showSuccess(context, 'Dokumen diupload');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(mitraProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text('Profil & Dokumen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (profile) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Baru (Dengan Trigger Pop-up)
                      Center(
                        child: GestureDetector(
                          onTap: () => _showLogoPicker(profile),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: profile.logoUrl != null &&
                                    profile.logoUrl!.isNotEmpty
                                ? NetworkImage(profile.logoUrl!)
                                : null,
                            child: profile.logoUrl == null ||
                                    profile.logoUrl!.isEmpty
                                ? const Icon(Icons.store, size: 40)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Informasi Bisnis',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _businessNameController,
                          label: 'Nama Bisnis',
                          icon: Icons.store),
                      const SizedBox(height: 12),
                      _buildTextField(
                          controller: _descriptionController,
                          label: 'Deskripsi',
                          icon: Icons.description,
                          maxLines: 3),
                      const SizedBox(height: 12),
                      _buildTextField(
                          controller: _MitraNameController,
                          label: 'Nama Pemilik',
                          icon: Icons.person),
                      const SizedBox(height: 32),
                      const Text('Dokumen',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      _buildDocUploadCard('Foto KTP', profile.ktpUrl,
                          () => _pickAndUploadDoc('ktp')),
                    ],
                  ),
                ),
              ),
            ),
            // Sticky Button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: _isLoading ? null : _submit,
                  child: const Text('Simpan Perubahan',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDocUploadCard(String title, String? url, VoidCallback onTap) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.upload_file),
      title: Text(title),
      trailing: Icon(url != null ? Icons.check_circle : Icons.chevron_right,
          color: url != null ? Colors.green : Colors.grey),
      onTap: onTap,
    );
  }
}
