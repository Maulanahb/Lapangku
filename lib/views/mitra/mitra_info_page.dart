import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/controllers/mitra/mitra_info_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/views/customer/change_password_page.dart';
import 'package:lapangku/views/mitra/edit_field_page.dart';
import 'package:lapangku/views/mitra/lapangan_saya_page.dart';

class MitraInfoPage extends ConsumerStatefulWidget {
  const MitraInfoPage({super.key});

  @override
  ConsumerState<MitraInfoPage> createState() => _MitraInfoPageState();
}

class _MitraInfoPageState extends ConsumerState<MitraInfoPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _namaLengkapCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nomorHpCtrl;
  late TextEditingController _alamatCtrl;
  late TextEditingController _namaPemilikBisnisCtrl;
  late TextEditingController _nomorKtpCtrl;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _namaLengkapCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _nomorHpCtrl = TextEditingController();
    _alamatCtrl = TextEditingController();
    _namaPemilikBisnisCtrl = TextEditingController();
    _nomorKtpCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _namaLengkapCtrl.dispose();
    _emailCtrl.dispose();
    _nomorHpCtrl.dispose();
    _alamatCtrl.dispose();
    _namaPemilikBisnisCtrl.dispose();
    _nomorKtpCtrl.dispose();
    super.dispose();
  }

  void _initFields(MitraProfileModel mitra) {
    if (!_isInit) {
      _namaLengkapCtrl.text = mitra.MitraName;
      _emailCtrl.text = mitra.email;
      _nomorHpCtrl.text = mitra.phone;
      _alamatCtrl.text = mitra.alamat;
      _namaPemilikBisnisCtrl.text = mitra.businessName;
      _nomorKtpCtrl.text = mitra.nomorKtp ?? '';
      _isInit = true;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null && mounted) {
      LoadingOverlay.show(context, message: 'Mengunggah foto...');
      try {
        await ref.read(mitraProfileProvider.notifier).uploadLogo(File(pickedFile.path));
        if (mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: AppColors.statusConfirmed),
          );
        }
      } catch (e) {
        if (mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = ref.read(mitraInfoControllerProvider.notifier);
    try {
      await controller.updateProfile(
        namaLengkap: _namaLengkapCtrl.text.trim(),
        nomorHp: _nomorHpCtrl.text.trim(),
        alamatDomisili: _alamatCtrl.text.trim(),
        nomorKtp: _nomorKtpCtrl.text.trim(),
        namaPemilikBisnis: _namaPemilikBisnisCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informasi pribadi berhasil disimpan!'), backgroundColor: AppColors.statusConfirmed),
        );
      }
    } catch (e) {
      // error is handled by state listener
    }
  }

  @override
  Widget build(BuildContext context) {
    final mitraAsync = ref.watch(mitraProfileProvider);
    final controllerState = ref.watch(mitraInfoControllerProvider);

    ref.listen<AsyncValue<void>>(
      mitraInfoControllerProvider,
      (previous, next) {
        if (next.isLoading) {
          LoadingOverlay.show(context, message: 'Menyimpan data...');
        } else if (previous?.isLoading == true) {
          LoadingOverlay.dismiss(context);
          if (next.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(next.error.toString()), backgroundColor: AppColors.error),
            );
          }
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundPageAlt,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPageAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pribadi',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Data identitas & Bisnis mitra',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: mitraAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (mitra) {
          _initFields(mitra);

          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeroCard(mitra),
                  
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 12),
                    child: Text('Informasi Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeading)),
                  ),
                  _buildSectionContainer(
                    children: [
                      _buildEditableField('Nama Lengkap', _namaLengkapCtrl, Icons.person_outline, minLength: 3),
                      _buildDivider(),
                      _buildReadOnlyField('Email', _emailCtrl, Icons.email_outlined),
                      _buildDivider(),
                      _buildEditableField('Nomor HP', _nomorHpCtrl, Icons.phone_outlined, isPhone: true),
                      _buildDivider(),
                      _buildPasswordField(context),
                      _buildDivider(),
                      _buildEditableField('Alamat Domisili', _alamatCtrl, Icons.location_on_outlined),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 12),
                    child: Text('Informasi Bisnis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeading)),
                  ),
                  _buildSectionContainer(
                    children: [
                      _buildEditableField('Nama Pemilik Bisnis', _namaPemilikBisnisCtrl, Icons.business_center_outlined),
                      _buildDivider(),
                      _buildEditableField('Nomor KTP', _nomorKtpCtrl, Icons.badge_outlined, isKtp: true),
                      _buildDivider(),
                      _buildStatusField(mitra.isVerified),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lapangan Terdaftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeading)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LapanganSayaPage()));
                          },
                          child: const Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  _buildLapanganList(),

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controllerState.isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          disabledBackgroundColor: AppColors.primaryDark.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: controllerState.isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan Informasi Pribadi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider, indent: 56, endIndent: 16);
  }

  Widget _buildHeroCard(MitraProfileModel mitra) {
    String joinYear = mitra.joinedAt?.year.toString() ?? DateTime.now().year.toString();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF165C38), // A bit lighter than primary dark
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF165C38).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mitra.isVerified)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Mitra Terverifikasi', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: (mitra.logoUrl != null && mitra.logoUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(mitra.logoUrl!)
                          : null,
                      child: (mitra.logoUrl == null || mitra.logoUrl!.isEmpty)
                          ? Text(
                              mitra.MitraName.isNotEmpty ? mitra.MitraName.substring(0, 1).toUpperCase() : 'M',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mitra.MitraName.isEmpty ? 'Nama Belum Diatur' : mitra.MitraName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(mitra.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(mitra.phone.isEmpty ? '-' : mitra.phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(mitra.totalFields.toString(), 'Lapangan'),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
              _buildStatItem(mitra.isVerified ? 'Aktif' : 'Pending', 'Status'),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
              _buildStatItem(joinYear, 'Bergabung'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {bool isPhone = false, bool isKtp = false, int minLength = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                TextFormField(
                  controller: controller,
                  keyboardType: isPhone ? TextInputType.phone : (isKtp ? TextInputType.number : TextInputType.text),
                  maxLength: isKtp ? 16 : null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 14, color: AppColors.textHeading, fontWeight: FontWeight.bold),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Tidak boleh kosong';
                    if (isPhone && value.length < 10) return 'Minimal 10 digit';
                    if (isKtp && value.length != 16) return 'KTP harus 16 digit';
                    if (minLength > 0 && value.length < minLength) return 'Minimal $minLength karakter';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  controller.text.isEmpty ? '-' : controller.text,
                  style: const TextStyle(fontSize: 14, color: AppColors.textHeading, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 24),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Password', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('********', style: TextStyle(fontSize: 14, color: AppColors.textHeading, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusField(bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.storefront_outlined, color: AppColors.textSecondary, size: 24),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Mitra', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVerified ? 'AKTIF' : 'PENDING',
                    style: TextStyle(
                      color: isVerified ? Colors.green[800] : Colors.orange[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLapanganList() {
    final uid = ref.watch(currentUidProvider);
    return StreamBuilder<List<MitraFieldModel>>(
      stream: ref.read(mitraInfoControllerProvider.notifier).getLapanganTerdaftar(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final fields = snapshot.data ?? [];
        if (fields.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Belum ada lapangan terdaftar.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fields.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final field = fields[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditFieldPage(field: field)),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: field.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: field.photoUrls.first,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.image, color: AppColors.primary),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.namaLapangan,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textHeading),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.sports_soccer, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                field.jenisLapangan,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: field.isActive ? Colors.green.withOpacity(0.2) : AppColors.backgroundInput,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              field.isActive ? 'AKTIF' : 'NONAKTIF',
                              style: TextStyle(
                                color: field.isActive ? Colors.green[800] : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
