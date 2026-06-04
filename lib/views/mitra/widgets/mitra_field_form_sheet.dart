import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk Whitelisting TextInput
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraFieldFormSheet extends ConsumerStatefulWidget {
  final MitraFieldModel? field;

  const MitraFieldFormSheet({super.key, this.field});

  @override
  ConsumerState<MitraFieldFormSheet> createState() =>
      _MitraFieldFormSheetState();
}

class _MitraFieldFormSheetState extends ConsumerState<MitraFieldFormSheet> {
  late TextEditingController _venueController;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  
  String _selectedJenis = 'Futsal';
  final List<String> _jenisOptions = [
    'Futsal',
    'Mini Soccer',
    'Badminton',
    'Basket'
  ];

  List<String> _selectedFasilitas = [];
  final List<String> _fasilitasOptions = [
    'Parkir',
    'Toilet',
    'Kantin',
    'Mushola',
    'Wifi',
    'Locker'
  ];

  // Foto lama (dari URL network Firebase)
  List<String> _existingPhotos = [];
  // Foto baru (dari lokal berkas galeri/kamera)
  final List<File> _newPhotos = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _venueController = TextEditingController(text: widget.field?.namaVenue ?? '');
    _nameController = TextEditingController(text: widget.field?.namaLapangan ?? '');
    _priceController = TextEditingController(
        text: widget.field?.hargaPerJam != null
            ? widget.field!.hargaPerJam.toString()
            : '');
    _descController = TextEditingController(text: widget.field?.deskripsi ?? '');

    if (widget.field != null) {
      _selectedJenis = widget.field!.jenisLapangan;
      _selectedFasilitas = List.from(widget.field!.fasilitas);
      _existingPhotos = List.from(widget.field!.photoUrls);
    }
  }

  // FIXED: Ditambahkan untuk mencegah kebocoran memori (Memory Leak)
  @override
  void dispose() {
    _venueController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Kompres sedikit agar upload lebih cepat
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked != null) {
        setState(() {
          _newPhotos.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, "Gagal mengambil gambar: $e");
    }
  }

  Future<void> _save() async {
    if (_venueController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      SnackbarHelper.showWarning(context, "Mohon isi semua kolom wajib!");
      return;
    }

    // FIXED: Aman dari FormatException Crash berkat tryParse
    final cleanPriceText = _priceController.text.replaceAll('.', '').trim();
    int? price = int.tryParse(cleanPriceText);
    if (price == null || price <= 0) {
      SnackbarHelper.showError(context, "Format harga per jam tidak valid!");
      return;
    }

    if (_existingPhotos.isEmpty && _newPhotos.isEmpty) {
      SnackbarHelper.showWarning(context, "Mohon unggah minimal 1 foto lapangan!");
      return;
    }

    final notifier = ref.read(mitraFieldProvider.notifier);
    bool success = false;

    if (widget.field == null) {
      // Create / Add New Field
      success = await notifier.addField(
        namaVenue: _venueController.text.trim(),
        namaLapangan: _nameController.text.trim(),
        jenisLapangan: _selectedJenis,
        hargaPerJam: price,
        deskripsi: _descController.text.trim(),
        fasilitas: _selectedFasilitas,
        photoFiles: _newPhotos,
      );
    } else {
      // Update / Edit Existing Field
      success = await notifier.editField(
        widget.field!.id,
        namaVenue: _venueController.text.trim(),
        namaLapangan: _nameController.text.trim(),
        jenisLapangan: _selectedJenis,
        hargaPerJam: price,
        deskripsi: _descController.text.trim(),
        fasilitas: _selectedFasilitas,
        photoUrls: _existingPhotos,
        newPhotoFiles: _newPhotos,
      );
    }

    if (mounted) {
      if (success) {
        SnackbarHelper.showSuccess(context, "Data lapangan berhasil disimpan!");
        Navigator.pop(context);
      } else {
        // Ambil pesan error dari state provider yang baru kita rancang
        final errorMsg = ref.read(mitraFieldProvider).errorMessage ?? "Terjadi kesalahan.";
        SnackbarHelper.showError(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldState = ref.watch(mitraFieldProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.field == null ? 'Tambah Lapangan Baru' : 'Edit Data Lapangan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _venueController,
              decoration: _inputDecor('Nama Venue / Lokasi *', Icons.business),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: _inputDecor('Nama Lapangan (e.g. Lapangan A) *', Icons.sports_soccer),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedJenis,
              decoration: _inputDecor('Jenis Olahraga', Icons.category),
              items: _jenisOptions.map((jenis) {
                return DropdownMenuItem(value: jenis, child: Text(jenis));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedJenis = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              // Membatasi hanya input angka saja
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecor('Harga Sewa Per Jam (IDR) *', Icons.attach_money),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputDecor('Deskripsi Lapangan (Opsional)', Icons.description),
            ),
            const SizedBox(height: 16),
            const Text('Fasilitas Lapangan',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _fasilitasOptions.map((f) {
                final isSelected = _selectedFasilitas.contains(f);
                return FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1B6B3A).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF1B6B3A),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFasilitas.add(f);
                      } else {
                        _selectedFasilitas.remove(f);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Foto Lapangan *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._existingPhotos.map((url) => _buildPhotoItem(
                        isNetwork: true,
                        url: url,
                        onRemove: () => setState(() => _existingPhotos.remove(url)),
                      )),
                  ..._newPhotos.map((file) => _buildPhotoItem(
                        isNetwork: false,
                        file: file,
                        onRemove: () => setState(() => _newPhotos.remove(file)),
                      )),
                  if (_existingPhotos.length + _newPhotos.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: fieldState.isMutating ? null : _save, // FIXED: Disable click saat loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B3A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey, // Indikasi visual loading
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: fieldState.isMutating
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan Data',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B6B3A))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // FIXED: Pengkondisian render ImageProvider tanpa cast paksa 'as'
  Widget _buildPhotoItem({
    required bool isNetwork,
    String? url,
    File? file,
    required VoidCallback onRemove,
  }) {
    ImageProvider imageProvider;
    if (isNetwork && url != null) {
      imageProvider = NetworkImage(url);
    } else if (!isNetwork && file != null) {
      imageProvider = FileImage(file);
    } else {
      imageProvider = const AssetImage('assets/images/placeholder.png'); // Fallback aman
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }
}