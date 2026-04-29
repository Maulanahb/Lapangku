import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lapangku/features/owner/field/models/owner_field_model.dart';
import 'package:lapangku/features/owner/field/providers/owner_field_provider.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class OwnerFieldFormSheet extends ConsumerStatefulWidget {
  final OwnerFieldModel? field;

  const OwnerFieldFormSheet({super.key, this.field});

  @override
  ConsumerState<OwnerFieldFormSheet> createState() => _OwnerFieldFormSheetState();
}

class _OwnerFieldFormSheetState extends ConsumerState<OwnerFieldFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  String _selectedJenis = 'Futsal';
  final List<String> _jenisOptions = ['Futsal', 'Mini Soccer', 'Badminton', 'Basket'];
  
  List<String> _selectedFasilitas = [];
  final List<String> _fasilitasOptions = ['Parkir', 'Toilet', 'Kantin', 'Mushola', 'Wifi', 'Ruang Ganti'];
  
  final List<File> _newPhotos = [];
  List<String> _existingPhotoUrls = [];
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _nameController = TextEditingController(text: f?.namaLapangan ?? '');
    _priceController = TextEditingController(text: f?.hargaPerJam.toString() ?? '');
    _descController = TextEditingController(text: f?.deskripsi ?? '');
    
    if (f != null) {
      if (_jenisOptions.contains(f.jenisLapangan)) {
        _selectedJenis = f.jenisLapangan;
      }
      _selectedFasilitas = List.from(f.fasilitas);
      _existingPhotoUrls = List.from(f.photoUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() {
        _newPhotos.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  void _removeNewPhoto(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  void _removeExistingPhoto(int index) {
    setState(() => _existingPhotoUrls.removeAt(index));
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Nama dan Harga wajib diisi');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final price = int.tryParse(_priceController.text.trim()) ?? 0;
      final desc = _descController.text.trim();

      if (widget.field != null) {
        // Edit
        final updatedField = widget.field!.copyWith(
          namaLapangan: name,
          jenisLapangan: _selectedJenis,
          hargaPerJam: price,
          deskripsi: desc,
          fasilitas: _selectedFasilitas,
          photoUrls: _existingPhotoUrls, // Keep remaining
        );
        
        await ref.read(ownerFieldProvider.notifier).editField(
          updatedField.id,
          namaLapangan: name,
          hargaPerJam: price,
          deskripsi: desc,
          fasilitas: _selectedFasilitas,
          newPhotoFiles: _newPhotos,
        );
        if (mounted) SnackbarHelper.showSuccess(context, 'Lapangan diperbarui');
      } else {
        // Add
        await ref.read(ownerFieldProvider.notifier).addField(
          namaLapangan: name,
          jenisLapangan: _selectedJenis,
          hargaPerJam: price,
          deskripsi: desc,
          fasilitas: _selectedFasilitas,
          photoFiles: _newPhotos,
        );
        if (mounted) SnackbarHelper.showSuccess(context, 'Lapangan ditambahkan');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.field != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Edit Lapangan' : 'Tambah Lapangan',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecor('Nama Lapangan', Icons.stadium),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedJenis,
                    decoration: _inputDecor('Jenis Lapangan', Icons.sports_soccer),
                    items: _jenisOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedJenis = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecor('Harga per Jam (Rp)', Icons.attach_money),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: _inputDecor('Deskripsi Lapangan', Icons.description).copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('Fasilitas Lapangan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _fasilitasOptions.map((fasilitas) {
                      final isSelected = _selectedFasilitas.contains(fasilitas);
                      return FilterChip(
                        label: Text(fasilitas),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD1FAE5),
                        checkmarkColor: const Color(0xFF1B6B3A),
                        labelStyle: TextStyle(color: isSelected ? const Color(0xFF1B6B3A) : Colors.black87),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) _selectedFasilitas.add(fasilitas);
                            else _selectedFasilitas.remove(fasilitas);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Foto Lapangan', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text('Tambah Foto'),
                      )
                    ],
                  ),
                  if (_existingPhotoUrls.isEmpty && _newPhotos.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Belum ada foto', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Existing
                          ..._existingPhotoUrls.asMap().entries.map((entry) => _buildPhotoItem(
                            isNetwork: true,
                            url: entry.value,
                            onRemove: () => _removeExistingPhoto(entry.key),
                          )),
                          // New
                          ..._newPhotos.asMap().entries.map((entry) => _buildPhotoItem(
                            isNetwork: false,
                            file: entry.value,
                            onRemove: () => _removeNewPhoto(entry.key),
                          )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6B3A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Lapangan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B6B3A))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildPhotoItem({required bool isNetwork, String? url, File? file, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: isNetwork ? NetworkImage(url!) as ImageProvider : FileImage(file!),
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
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
