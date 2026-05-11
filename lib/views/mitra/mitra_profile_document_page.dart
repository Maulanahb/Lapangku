import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraProfileDocumentPage extends ConsumerStatefulWidget {
  const MitraProfileDocumentPage({super.key});

  @override
  ConsumerState<MitraProfileDocumentPage> createState() =>
      _MitraProfileDocumentPageState();
}

class _MitraProfileDocumentPageState
    extends ConsumerState<MitraProfileDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _MitraNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

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
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _MitraNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Profil berhasil diperbarui');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(mitraProfileProvider.notifier).uploadLogo(File(picked.path));
      if (mounted) SnackbarHelper.showSuccess(context, 'Logo berhasil diupload');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal upload logo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadDoc(String docType) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(mitraProfileProvider.notifier).uploadDocument(docType, File(picked.path));
      if (mounted) SnackbarHelper.showSuccess(context, 'Dokumen berhasil diupload');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal upload dokumen: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(mitraProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Profil & Dokumen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Bisnis
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
                            ],
                            image: profile.logoUrl != null && profile.logoUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(profile.logoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profile.logoUrl == null || profile.logoUrl!.isEmpty
                              ? const Icon(Icons.store, size: 40, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _pickAndUploadLogo,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1B6B3A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Informasi Bisnis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _businessNameController,
                    label: 'Nama Bisnis / Lapangan',
                    icon: Icons.store,
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Deskripsi Singkat',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _MitraNameController,
                    label: 'Nama Pemilik',
                    icon: Icons.person,
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Bisnis',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Nomor WhatsApp',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Alamat Lengkap',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  const Text('Dokumen Verifikasi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                profile.isVerified
                                    ? 'Dokumen Anda sudah diverifikasi oleh admin LapangKu.'
                                    : 'Dokumen sedang menunggu verifikasi.',
                                style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDocUploadCard(
                    title: 'Foto KTP Pemilik',
                    url: profile.ktpUrl,
                    onTap: () => _pickAndUploadDoc('ktp'),
                  ),
                  const SizedBox(height: 12),
                  _buildDocUploadCard(
                    title: 'Foto NPWP Bisnis (Opsional)',
                    url: profile.npwpUrl,
                    onTap: () => _pickAndUploadDoc('npwp'),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B3A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Perubahan',
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
      ),
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    String? url,
    required VoidCallback onTap,
  }) {
    final hasDoc = url != null && url.isNotEmpty;
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: hasDoc ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                image: hasDoc 
                    ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                    : null,
              ),
              child: hasDoc 
                  ? null 
                  : Icon(Icons.upload_file, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(hasDoc ? 'Dokumen terupload' : 'Ketuk untuk upload',
                      style: TextStyle(
                          color: hasDoc ? Colors.green : Colors.grey.shade500,
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(hasDoc ? Icons.check_circle : Icons.chevron_right,
                color: hasDoc ? Colors.green : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B6B3A))),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
