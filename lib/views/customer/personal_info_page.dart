import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';

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
  late TextEditingController _addressController;
  
  final FocusNode _phoneFocusNode = FocusNode();
  
  String? _selectedGender;
  String? _selectedCity;
  DateTime? _selectedDate;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _populateData(UserModel user) {
    if (!_isInitialized) {
      _nameController.text = user.nama;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _selectedGender = user.gender ?? 'Laki-laki';
      _selectedCity = user.city ?? 'Malang, Jawa Timur';
      
      if (user.birthday != null) {
        try {
          _selectedDate = DateFormat('dd MMMM yyyy', 'id').parse(user.birthday!);
        } catch (e) {
          // Handle parsing error if format doesn't match
        }
      }
      _isInitialized = true;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCityPicker() {
    final List<String> cities = [
      'Malang, Jawa Timur',
      'Surabaya, Jawa Timur',
      'Jakarta Pusat, DKI Jakarta',
      'Bandung, Jawa Barat',
      'Yogyakarta, DIY',
      'Semarang, Jawa Tengah',
      'Medan, Sumatera Utara',
      'Makassar, Sulawesi Selatan',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Kota',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeading),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(cities[index]),
                    trailing: _selectedCity == cities[index] ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      setState(() => _selectedCity = cities[index]);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingOverlay.show(context, message: 'Menyimpan perubahan...');

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        String? birthdayStr;
        if (_selectedDate != null) {
          birthdayStr = DateFormat('dd MMMM yyyy', 'id').format(_selectedDate!);
        }

        await ref.read(authProvider.notifier).updateProfile(
              uid: user.uid,
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              gender: _selectedGender,
              city: _selectedCity,
              address: _addressController.text.trim(),
              birthday: birthdayStr,
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                  _buildProgressCard(),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Informasi Dasar'),
                  
                  _buildEditableField(
                    label: 'NAMA LENGKAP',
                    controller: _nameController,
                    validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  
                  _buildEditableField(
                    label: 'EMAIL',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Format email tidak valid';
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
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nomor HP tidak boleh kosong';
                      if (v.length < 10) return 'Minimal 10 digit';
                      return null;
                    },
                  ),

                  _buildClickableField(
                    label: 'TANGGAL LAHIR',
                    value: _selectedDate != null ? DateFormat('dd MMMM yyyy', 'id').format(_selectedDate!) : 'Pilih Tanggal Lahir',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _selectDate(context),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Informasi Tambahan'),
                  _buildGenderField(),
                  
                  _buildClickableField(
                    label: 'KOTA',
                    value: _selectedCity ?? 'Pilih Kota',
                    icon: Icons.keyboard_arrow_down,
                    onTap: _showCityPicker,
                  ),
                  
                  _buildAddressField(),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final String initials = user.nama.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase();

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
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
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

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil Kamu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Lengkapi data pribadi',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Text(
                '85%',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.85,
              backgroundColor: AppColors.backgroundPage,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: trailing != null ? Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [trailing],
                ),
              ) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
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
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundField,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(icon, color: AppColors.hint, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JENIS KELAMIN',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundField,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildGenderOption('Laki-laki'),
                _buildGenderOption('Perempuan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label) {
    bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALAMAT',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundField,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Masukkan alamat lengkap...',
                hintStyle: TextStyle(color: AppColors.hint, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(color: AppColors.textDark, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
