import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

// Import Langkah-langkah
import 'step1_account.dart';
import 'step2_identity.dart';
import 'step3_field_info.dart';
import 'step4_location.dart';
import 'step5_photos.dart';
import 'step6_schedule.dart';
import 'step7_review.dart';

class OwnerRegisterPage extends ConsumerStatefulWidget {
  const OwnerRegisterPage({super.key});

  @override
  ConsumerState<OwnerRegisterPage> createState() => _OwnerRegisterPageState();
}

class _OwnerRegisterPageState extends ConsumerState<OwnerRegisterPage> {
  int _currentStep = 1;
  final int _totalSteps = 7;
  bool _isSubmitting = false;

  // Step 1: Account
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 3: Field Info
  final _fieldNameController = TextEditingController();
  final _fieldDescriptionController = TextEditingController();
  String _selectedSport = 'Futsal';
  List<String> _selectedFacilities = ['Parkir', 'Wifi', 'Mushola'];

  // Step 4: Location
  final _addressController = TextEditingController();

  // Step 6: Schedule
  final _priceController = TextEditingController();
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  List<String> _selectedDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  // Photos
  File? _ktpPhoto;
  File? _selfiePhoto;
  List<File> _fieldPhotos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _fieldNameController.dispose();
    _fieldDescriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isKtp}) async {
    final pickedFile =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        if (isKtp) {
          _ktpPhoto = File(pickedFile.path);
        } else {
          _selfiePhoto = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _pickFieldPhotos() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _fieldPhotos.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  void _nextStep() {
    // Validasi step 1 sebelum lanjut
    if (_currentStep == 1) {
      final err = _validateStep1();
      if (err != null) {
        SnackbarHelper.showError(context, err);
        return;
      }
    }
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  String? _validateStep1() {
    if (_businessNameController.text.trim().isEmpty) {
      return 'Nama bisnis wajib diisi';
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      return 'Email tidak valid';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'No. telepon wajib diisi';
    }
    if (_passwordController.text.length < 6) {
      return 'Password minimal 6 karakter';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    try {
      // 1. Buat akun di Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final uid = credential.user!.uid;

      // 2. Simpan profil owner ke koleksi 'owners'
      await FirebaseFirestore.instance.collection('owners').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'namaBisnis': _businessNameController.text.trim(),
        'ownerName': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'telepon': _phoneController.text.trim(),
        'isVerified': false,
        'notificationOrder': true,
        'notificationPromo': false,
        'totalFields': 0,
        'totalOrders': 0,
        'rating': 0.0,
        'bankName': '',
        'bankAccount': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Simpan user ke koleksi 'users' (untuk auth routing)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'nama': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'owner',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Logout lalu minta login ulang agar role terbaca dengan benar
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Akun berhasil dibuat! Silakan login.',
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Terjadi kesalahan. Coba lagi.';
        if (e.code == 'email-already-in-use') {
          msg = 'Email sudah digunakan. Gunakan email lain.';
        } else if (e.code == 'weak-password') {
          msg = 'Password terlalu lemah. Minimal 6 karakter.';
        } else if (e.code == 'invalid-email') {
          msg = 'Format email tidak valid.';
        }
        SnackbarHelper.showError(context, msg);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal mendaftar: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStepContent(),
              ),
            ),
            _buildBottomButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
        onPressed: _isSubmitting ? null : _prevStep,
      ),
      title: const Text(
        'LapangKu',
        style: TextStyle(
          color: Color(0xFF1B6B3A),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressBar() {
    if (_currentStep == _totalSteps) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Langkah $_currentStep dari $_totalSteps',
            style: const TextStyle(
                color: Color(0xFF1B6B3A),
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentStep / _totalSteps,
              backgroundColor: const Color(0xFFEDF2F7),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1B6B3A)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Step1Account(
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          businessNameController: _businessNameController,
          phoneController: _phoneController,
        );
      case 2:
        return Step2Identity(
          ktpPhoto: _ktpPhoto,
          selfiePhoto: _selfiePhoto,
          onPickKtp: () => _pickImage(ImageSource.gallery, isKtp: true),
          onPickSelfie: () => _pickImage(ImageSource.camera, isKtp: false),
        );
      case 3:
        return Step3FieldInfo(
          nameController: _fieldNameController,
          descriptionController: _fieldDescriptionController,
          selectedSport: _selectedSport,
          onSportSelected: (sport) => setState(() => _selectedSport = sport),
          selectedFacilities: _selectedFacilities,
          onFacilityToggled: (facility) {
            setState(() {
              if (_selectedFacilities.contains(facility)) {
                _selectedFacilities.remove(facility);
              } else {
                _selectedFacilities.add(facility);
              }
            });
          },
        );
      case 4:
        return Step4Location(addressController: _addressController);
      case 5:
        return Step5Photos(
          fieldPhotos: _fieldPhotos,
          onPickPhotos: _pickFieldPhotos,
          onRemovePhoto: (index) {
            setState(() => _fieldPhotos.removeAt(index));
          },
        );
      case 6:
        return Step6Schedule(
          priceController: _priceController,
          openingTime: _openingTime,
          closingTime: _closingTime,
          selectedDays: _selectedDays,
          onPickOpeningTime: () async {
            final time =
                await showTimePicker(context: context, initialTime: _openingTime);
            if (time != null) setState(() => _openingTime = time);
          },
          onPickClosingTime: () async {
            final time =
                await showTimePicker(context: context, initialTime: _closingTime);
            if (time != null) setState(() => _closingTime = time);
          },
          onDayToggled: (day) {
            setState(() {
              if (_selectedDays.contains(day)) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
        );
      case 7:
        return Step7Review(
          contact: _phoneController.text,
          fieldName: _fieldNameController.text,
          fieldDescription: _fieldDescriptionController.text,
          address: _addressController.text,
          price: _priceController.text,
          ktpPhoto: _ktpPhoto,
          selfiePhoto: _selfiePhoto,
          fieldPhotos: _fieldPhotos,
          onEditStep: (step) => setState(() => _currentStep = step),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == _totalSteps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F5A2F),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? 'Daftar Sekarang' : 'Lanjutkan',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep
                          ? Icons.check_circle
                          : Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
