import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:lapangku/standards/constants/app_colors.dart'; // Pastikan import ini ada

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
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankAccountNameController;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // UX: Tutup keyboard saat loading
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
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Menampilkan Bottom Sheet modern untuk opsi perubahan foto profil.
  void _showLogoBottomSheet(String? logoUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 20),
              // Opsi: Ambil dari Kamera
              _buildBottomSheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Ambil dari Kamera',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadLogoFromSource(ImageSource.camera);
                },
              ),
              // Opsi: Pilih dari Galeri
              _buildBottomSheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadLogoFromSource(ImageSource.gallery);
                },
              ),
              // Opsi: Hapus Foto (hanya jika logo ada)
              if (logoUrl != null && logoUrl.isNotEmpty)
                _buildBottomSheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus Foto',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteLogo();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Widget builder untuk setiap opsi di dalam Bottom Sheet.
  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mengambil gambar dari sumber (kamera/galeri) lalu upload sebagai logo.
  Future<void> _pickAndUploadLogoFromSource(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(mitraProfileProvider.notifier)
          .uploadLogo(File(picked.path));
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Logo berhasil diupload');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal upload logo: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menghapus foto profil (logo).
  Future<void> _deleteLogo() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(mitraProfileProvider.notifier).deleteLogo();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Foto profil berhasil dihapus');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal menghapus foto: $e');
      }
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
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Dokumen berhasil diupload');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal upload dokumen: $e');
      }
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
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0, // Dibuat flat dengan body
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (profile) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ─── HERO SECTION (AVATAR LOGO) ───
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 40, top: 16),
                        child: Center(
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => _showLogoBottomSheet(profile.logoUrl),
                            child: Stack(
                              children: [
                                Container(
                                  key: ValueKey(profile.logoUrl),
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          offset: Offset(0, 4))
                                    ],
                                    image: profile.logoUrl != null &&
                                            profile.logoUrl!.isNotEmpty
                                        ? DecorationImage(
                                            image:
                                                NetworkImage(profile.logoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: profile.logoUrl == null ||
                                          profile.logoUrl!.isEmpty
                                      ? const Icon(Icons.storefront_rounded,
                                          size: 50, color: Colors.grey)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        color: AppColors.primary, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─── FORM SECTION ───
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.backgroundPage,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── INFORMASI BISNIS ──
                                const SizedBox(height: 16),
                                const Text('Informasi Bisnis',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textHeading)),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _businessNameController,
                                  label: 'Nama Bisnis / Lapangan',
                                  hint: 'Contoh: Lapangku Futsal',
                                  icon: Icons.store_rounded,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _descriptionController,
                                  label: 'Deskripsi Singkat',
                                  hint:
                                      'Ceritakan sedikit tentang lapangan Anda',
                                  icon: Icons.description_outlined,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _MitraNameController,
                                  label: 'Nama Pemilik',
                                  hint: 'Nama lengkap pemilik',
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _emailController,
                                  label: 'Email Bisnis',
                                  hint: 'contoh@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _phoneController,
                                  label: 'Nomor WhatsApp',
                                  hint: 'Contoh: 0812...',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _addressController,
                                  label: 'Alamat Lengkap',
                                  hint: 'Masukkan alamat lengkap lapangan',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                ),

                                // ── INFORMASI REKENING ──
                                const SizedBox(height: 32),
                                const Text('Informasi Rekening',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textHeading)),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _bankNameController,
                                  label: 'Nama Bank',
                                  hint: 'Contoh: BCA, Mandiri, BRI',
                                  icon: Icons.account_balance_rounded,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _bankAccountController,
                                  label: 'Nomor Rekening',
                                  hint: 'Masukkan nomor rekening',
                                  icon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),

                                _buildModernTextField(
                                  controller: _bankAccountNameController,
                                  label: 'Atas Nama Rekening',
                                  hint: 'Nama pemilik rekening',
                                  icon: Icons.account_box_outlined,
                                ),

                                // ── DOKUMEN VERIFIKASI ──
                                const SizedBox(height: 32),
                                const Text('Dokumen Verifikasi',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textHeading)),
                                const SizedBox(height: 12),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.blue.withOpacity(0.2))),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          color: Colors.blue, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          profile.isVerified
                                              ? 'Dokumen Anda sudah diverifikasi oleh admin LapangKu.'
                                              : 'Dokumen sedang menunggu verifikasi oleh tim admin.',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              height: 1.4),
                                        ),
                                      ),
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
                                const SizedBox(
                                    height:
                                        40), // Spacing bawah sebelum sticky button
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── STICKY BOTTOM BUTTON ───
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Simpan Perubahan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── WIDGET BANTUAN DENGAN UI BARU ───

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          style: const TextStyle(fontSize: 14, color: AppColors.textHeading),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                  bottom: maxLines > 1
                      ? (maxLines * 12.0)
                      : 0), // Adjust icon for multiline
              child: Icon(icon, color: AppColors.textSecondary, size: 22),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: hasDoc
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
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
                color: hasDoc ? AppColors.primaryLight : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                image: hasDoc
                    ? DecorationImage(
                        image: NetworkImage(url), fit: BoxFit.cover)
                    : null,
              ),
              child: hasDoc
                  ? null
                  : Icon(Icons.upload_file_rounded,
                      color: Colors.grey.shade400, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textHeading)),
                  const SizedBox(height: 4),
                  Text(hasDoc ? 'Dokumen terupload' : 'Ketuk untuk upload file',
                      style: TextStyle(
                          color: hasDoc
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(
                hasDoc
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: hasDoc ? AppColors.primary : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
