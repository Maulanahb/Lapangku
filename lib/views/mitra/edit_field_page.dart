import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/controllers/mitra/mitra_location_controller.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:lapangku/views/mitra/widgets/field_form_widgets.dart';
import 'package:lapangku/views/mitra/mitra_map_picker_page.dart';

class EditFieldPage extends ConsumerStatefulWidget {
  final MitraFieldModel field;
  const EditFieldPage({super.key, required this.field});

  @override
  ConsumerState<EditFieldPage> createState() => _EditFieldPageState();
}

class _EditFieldPageState extends ConsumerState<EditFieldPage> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  bool _isSubmitting = false;

  late TextEditingController _venueController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late String _selectedSport;
  late String _selectedTipe;
  late List<String> _selectedFacilities;
  late TimeOfDay _openingTime;
  late TimeOfDay _closingTime;

  bool _useWeekendPrice = false;
  late TextEditingController _weekendPriceController;

  final List<File> _photoFiles = [];
  late List<String> _existingPhotoUrls;
  final ImagePicker _picker = ImagePicker();

  final Color _primaryGreen = const Color(0xFF0F5A3C);
  final Color _textGrey = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _venueController = TextEditingController(text: f.namaVenue);
    _nameController = TextEditingController(text: f.namaLapangan);
    _addressController = TextEditingController(text: f.alamat);
    _priceController = TextEditingController(text: f.hargaPerJam.toString());
    _descriptionController = TextEditingController(text: f.deskripsi);
    _selectedSport = f.jenisLapangan;
    _selectedTipe = f.tipeLapangan;
    _selectedFacilities = List.from(f.fasilitas);
    _existingPhotoUrls = List.from(f.photoUrls);
    _openingTime = _parseTime(f.jamBuka);
    _closingTime = _parseTime(f.jamTutup);
    _weekendPriceController = TextEditingController();
    if (f.hargaWeekend != null && f.hargaWeekend! > 0) {
      _useWeekendPrice = true;
      _weekendPriceController.text = f.hargaWeekend.toString();
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _venueController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _weekendPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photoFiles.length + _existingPhotoUrls.length >= 5) {
      SnackbarHelper.showError(context, 'Maksimal 5 foto');
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked != null) {
      setState(() => _photoFiles.add(File(picked.path)));
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_venueController.text.isEmpty)
        return SnackbarHelper.showError(
            context, 'Nama Venue/Tempat wajib diisi');
      if (_nameController.text.isEmpty)
        return SnackbarHelper.showError(context, 'Nama lapangan wajib diisi');
      if (_addressController.text.isEmpty)
        return SnackbarHelper.showError(context, 'Alamat wajib diisi');
    } else if (_currentStep == 2) {
      if (_priceController.text.isEmpty)
        return SnackbarHelper.showError(context, 'Harga wajib diisi');
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(mitraFieldProvider.notifier);
      final locationState = ref.read(mitraLocationProvider);

      if (_photoFiles.isNotEmpty) {
        SnackbarHelper.showInfo(
            context, 'Mengunggah ${_photoFiles.length} foto baru...');
      }

      // Gunakan koordinat dari locationProvider jika ada, fallback ke koordinat existing
      final lat = locationState.latitude ?? widget.field.latitude;
      final lng = locationState.longitude ?? widget.field.longitude;

      await notifier.editField(
        widget.field.id,
        namaVenue: _venueController.text,
        namaLapangan: _nameController.text,
        jenisLapangan: _selectedSport,
        tipeLapangan: _selectedTipe,
        hargaPerJam: int.parse(_priceController.text),
        hargaWeekend: _useWeekendPrice
            ? int.tryParse(_weekendPriceController.text)
            : null,
        jamBuka: _formatTime(_openingTime),
        jamTutup: _formatTime(_closingTime),
        alamat: _addressController.text,
        latitude: lat,
        longitude: lng,
        deskripsi: _descriptionController.text,
        fasilitas: _selectedFacilities,
        photoUrls: _existingPhotoUrls,
        newPhotoFiles: _photoFiles,
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Lapangan berhasil diperbarui');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          FieldFormWidgets.buildProgressBar(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            labels: ['Info Dasar', 'Jadwal & Harga', 'Fasilitas'],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1B6B3A)),
        onPressed: _prevStep,
      ),
      title: const Text('Edit Lapangan',
          style: TextStyle(
              color: Color(0xFF1A202C),
              fontWeight: FontWeight.w900,
              fontSize: 18)),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    final locationState = ref.watch(mitraLocationProvider);
    ref.listen<LocationState>(mitraLocationProvider, (previous, next) {
      if (previous?.address != next.address && next.address.isNotEmpty) {
        _addressController.text = next.address;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldFormWidgets.buildSectionHeader(
            'Foto Lapangan', 'Unggah foto terbaik untuk menarik pelanggan'),
        const SizedBox(height: 16),
        _buildPhotoPicker(),
        const SizedBox(height: 32),
        FieldFormWidgets.buildSectionHeader('Informasi Dasar', null),
        const SizedBox(height: 16),
        FieldFormWidgets.buildLabel('Nama Tempat / Venue'),
        FieldFormWidgets.buildTextField(_venueController, 'Contoh: SM Futsal'),
        const SizedBox(height: 20),
        FieldFormWidgets.buildLabel('Nama Lapangan'),
        FieldFormWidgets.buildTextField(
            _nameController, 'Masukkan nama lapangan...'),
        const SizedBox(height: 20),
        FieldFormWidgets.buildLabel('Jenis Olahraga'),
        _buildSportChips(),
        const SizedBox(height: 20),
        FieldFormWidgets.buildLabel('Tipe Lapangan'),
        _buildTipeChips(),
        const SizedBox(height: 24),
        FieldFormWidgets.buildLabel('Lokasi Peta'),
        _buildLocationPicker(),
        const SizedBox(height: 16),
        _buildMyLocationButton(locationState),
        const SizedBox(height: 24),
        FieldFormWidgets.buildLabel('Alamat Lengkap'),
        FieldFormWidgets.buildTextField(_addressController,
            'Jl. Soekarno Hatta No. 9, Malang (Sesuai Google Maps)',
            maxLines: 3),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldFormWidgets.buildSectionHeader('Jam Operasional', null),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildTimePicker('Buka', _openingTime,
                    (t) => setState(() => _openingTime = t))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTimePicker('Tutup', _closingTime,
                    (t) => setState(() => _closingTime = t))),
          ],
        ),
        const SizedBox(height: 32),
        FieldFormWidgets.buildSectionHeader('Harga per Jam', null),
        const SizedBox(height: 16),
        FieldFormWidgets.buildLabel('Harga Reguler (Senin - Jumat)'),
        FieldFormWidgets.buildPriceField(_priceController, 'Contoh: 120000'),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Harga Weekend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Switch(
              value: _useWeekendPrice,
              onChanged: (val) => setState(() => _useWeekendPrice = val),
              activeTrackColor: const Color(0xFF1B6B3A),
              activeThumbColor: Colors.white,
            ),
          ],
        ),
        Text('Gunakan harga berbeda untuk Sabtu - Minggu',
            style: TextStyle(color: _textGrey, fontSize: 13)),
        if (_useWeekendPrice) ...[
          const SizedBox(height: 16),
          FieldFormWidgets.buildLabel('Harga Weekend (Sabtu - Minggu)'),
          FieldFormWidgets.buildPriceField(
              _weekendPriceController, 'Contoh: 150000'),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Fasilitas',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F5A3C))),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: facilitiesList.length,
          itemBuilder: (context, index) {
            final facility = facilitiesList[index];
            final isSelected = _selectedFacilities.contains(facility['name']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFacilities.remove(facility['name']);
                  } else {
                    _selectedFacilities.add(facility['name'] as String);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEEF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F5A3C)
                        : const Color(0xFFF3F4F6),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(facility['icon'] as IconData,
                        color: isSelected
                            ? const Color(0xFF0F5A3C)
                            : const Color(0xFF4A5568),
                        size: 30),
                    const SizedBox(height: 10),
                    Text(facility['name'] as String,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0F5A3C)
                                : const Color(0xFF4A5568))),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        FieldFormWidgets.buildSectionHeader(
            'Deskripsi Lapangan (opsional)', null),
        const SizedBox(height: 12),
        _buildDescriptionField(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    final allItems = [
      ..._existingPhotoUrls.map((url) => {'type': 'url', 'value': url}),
      ..._photoFiles.map((file) => {'type': 'file', 'value': file}),
    ];

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: allItems.isNotEmpty
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: allItems[0]['type'] == 'url'
                            ? Image.network(allItems[0]['value']! as String,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover)
                            : Image.file(allItems[0]['value']! as File,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover),
                      ),
                      // Badge Foto Utama
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5A3C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Foto Utama',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      FieldFormWidgets.buildPositionDetector(onTap: () {
                        setState(() {
                          if (allItems[0]['type'] == 'url') {
                            _existingPhotoUrls.removeAt(0);
                          } else {
                            _photoFiles.removeAt(0);
                          }
                        });
                      }),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 40, color: Color(0xFF1B6B3A)),
                      const SizedBox(height: 12),
                      const Text('Tambah Foto Utama',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Maks. 5MB (JPG/PNG)',
                          style: TextStyle(color: _textGrey, fontSize: 12)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final itemIndex = index + 1;
            bool hasItem = itemIndex < allItems.length;
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: hasItem
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: allItems[itemIndex]['type'] == 'url'
                              ? Image.network(
                                  allItems[itemIndex]['value']! as String,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover)
                              : Image.file(allItems[itemIndex]['value']! as File,
                                  width: 70, height: 70, fit: BoxFit.cover),
                        ),
                        FieldFormWidgets.buildPositionDetector(onTap: () {
                          setState(() {
                            if (allItems[itemIndex]['type'] == 'url') {
                              _existingPhotoUrls
                                  .remove(allItems[itemIndex]['value']);
                            } else {
                              _photoFiles.remove(allItems[itemIndex]['value']);
                            }
                          });
                        }),
                      ],
                    )
                  : GestureDetector(
                      onTap: _pickImage,
                      child: const Center(
                          child: Icon(Icons.add, color: Color(0xFF9CA3AF))),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSportChips() {
    final sports = ['Futsal', 'Badminton', 'Basket', 'Tenis', 'Mini Soccer'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sports.map((sport) {
        bool isSelected = _selectedSport == sport;
        return GestureDetector(
          onTap: () => setState(() => _selectedSport = sport),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F5A3C)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(30)),
            child: Text(sport,
                style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipeChips() {
    final types = ['Indoor', 'Outdoor'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((tipe) {
        bool isSelected = _selectedTipe == tipe;
        return GestureDetector(
          onTap: () => setState(() => _selectedTipe = tipe),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F5A3C)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tipe == 'Indoor' ? Icons.roofing : Icons.wb_sunny_outlined,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF1E40AF),
                ),
                const SizedBox(width: 6),
                Text(tipe,
                    style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF1E40AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationPicker() {
    final locationState = ref.watch(mitraLocationProvider);
    // Cek apakah sudah ada lokasi dari picker ATAU dari data existing
    final hasLocation =
        (locationState.latitude != null && locationState.longitude != null) ||
            (widget.field.latitude != 0.0 && widget.field.longitude != 0.0);
    final displayLat = locationState.latitude ?? widget.field.latitude;
    final displayLng = locationState.longitude ?? widget.field.longitude;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<MapPickerResult>(
          context,
          MaterialPageRoute(
            builder: (_) => MitraMapPickerPage(
              initialLat: displayLat,
              initialLng: displayLng,
            ),
          ),
        );
        if (result != null) {
          ref.read(mitraLocationProvider.notifier).updateLocation(
                result.latitude,
                result.longitude,
              );
          _addressController.text = result.address;
        }
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF0F4FF),
          border: Border.all(
            color:
                hasLocation ? const Color(0xFF0F5A3C) : const Color(0xFFE2E8F0),
            width: hasLocation ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasLocation ? Icons.check_circle : Icons.map_outlined,
                color: hasLocation
                    ? const Color(0xFF0F5A3C)
                    : const Color(0xFF718096),
                size: 36,
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF1B6B3A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    hasLocation
                        ? 'Ubah Lokasi di Peta'
                        : 'Pilih Lokasi di Peta',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ]),
              ),
              if (hasLocation && displayLat != 0.0) ...[
                const SizedBox(height: 8),
                Text(
                  '${displayLat.toStringAsFixed(5)}, ${displayLng.toStringAsFixed(5)}',
                  style:
                      const TextStyle(color: Color(0xFF718096), fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton(LocationState locationState) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton.icon(
        onPressed: locationState.isLoading
            ? null
            : () async {
                try {
                  await ref
                      .read(mitraLocationProvider.notifier)
                      .getCurrentLocation();
                } catch (e) {
                  if (mounted) SnackbarHelper.showError(context, e.toString());
                }
              },
        icon: locationState.isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF2C5282)))
            : const Icon(Icons.my_location_rounded,
                size: 20, color: Color(0xFF2C5282)),
        label: Text(
            locationState.isLoading ? 'Mencari...' : 'Gunakan lokasi saya',
            style: const TextStyle(
                color: Color(0xFF2C5282),
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEDF2FF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildTimePicker(
      String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldFormWidgets.buildLabel(label),
        GestureDetector(
          onTap: () async {
            final picked =
                await showTimePicker(context: context, initialTime: time);
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.access_time, size: 20, color: Color(0xFF1B6B3A)),
              const SizedBox(width: 12),
              Text(time.format(context),
                  style: const TextStyle(fontWeight: FontWeight.bold))
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
              controller: _descriptionController,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                  hintText:
                      'Contoh: Aturan penggunaan sepatu, kondisi rumput, dsb.',
                  hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                  border: InputBorder.none,
                  counterText: ''),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          Text('${_descriptionController.text.length}/500',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    String primaryLabel = _currentStep < _totalSteps
        ? 'Lanjut ke ${_currentStep == 1 ? 'Jadwal' : 'Fasilitas'}'
        : 'Simpan Perubahan';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5))
      ]),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5A3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(primaryLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Simpan Draf',
                  style: TextStyle(
                      color: Color(0xFF0F5A3C), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
