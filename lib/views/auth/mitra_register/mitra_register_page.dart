import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:email_otp/email_otp.dart';

// Import Langkah-langkah
import 'step1_account.dart';
import 'step2_password.dart';
import 'step3_identity.dart';
import 'step4_field_info.dart';
import 'step5_location.dart';
import 'step6_photos.dart';
import 'step7_schedule.dart';
import 'step8_review.dart';
import 'mitra_waiting_page.dart';

class MitraRegisterPage extends ConsumerStatefulWidget {
  final String? email;
  final bool otpAlreadySent;
  const MitraRegisterPage({super.key, this.email, this.otpAlreadySent = false});

  @override
  ConsumerState<MitraRegisterPage> createState() => _MitraRegisterPageState();
}

class _MitraRegisterPageState extends ConsumerState<MitraRegisterPage> {
  int _currentStep = 1;
  final int _totalSteps = 8;
  bool _isSubmitting = false;

  // Controllers
  final _emailController = TextEditingController();
  // Controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // OTP State
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  int _resendTimer = 60;
  Timer? _timer;

  void _startTimer() => _startResendTimer();

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  // Field Info
  final _fieldNameController = TextEditingController();
  final _fieldDescriptionController = TextEditingController();
  String _selectedSport = 'Futsal';
  String _selectedFieldType = 'Indoor';
  final List<String> _selectedFacilities = [];

  // Location
  final _addressController = TextEditingController();

  // Schedule
  final _priceController = TextEditingController();
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  final List<String> _selectedDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  // Photos
  File? _ktpPhoto;
  File? _selfiePhoto;
  final List<File> _fieldPhotos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
      if (widget.otpAlreadySent) {
        _isOtpSent = true;
        _startResendTimer();
      } else {
        // Auto send OTP on load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendOtp();
        });
      }
    }

    // Add listeners to all OTP controllers
    for (var controller in _otpControllers) {
      controller.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _fieldNameController.dispose();
    _fieldDescriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      SnackbarHelper.showError(context, 'Alamat email tidak valid');
      return;
    }


    try {
      EmailOTP.config(
        appName: "LapangKu Mitra",
        otpType: OTPType.numeric,
        otpLength: 6,
        appEmail: 'lapangku1@gmail.com',
      );

      EmailOTP.setTemplate(
        template: '''
          <div style="background-color: #f6f9fc; padding: 40px 20px; font-family: 'Helvetica Neue', Arial, sans-serif;">
            <div style="max-width: 450px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.05);">
              <div style="background-color: #1B6B3A; padding: 30px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 1px;">LAPANGKU</h1>
              </div>
              <div style="padding: 40px 35px;">
                <h2 style="color: #1B6B3A; margin: 0 0 15px; font-size: 20px; font-weight: 700;">LapangKu Mitra</h2>
                <p style="color: #4a5568; line-height: 1.6; margin: 0 0 25px; font-size: 16px;">Halo,</p>
                <p style="color: #4a5568; line-height: 1.6; margin: 0 0 30px; font-size: 16px;">Berikut adalah kode verifikasi Anda untuk masuk ke aplikasi:</p>
                
                <div style="background-color: #f7fafc; border: 1px dashed #cbd5e0; border-radius: 12px; padding: 25px; text-align: center; margin-bottom: 30px;">
                  <span style="font-size: 36px; font-weight: 900; letter-spacing: 10px; color: #1B6B3A;">{{otp}}</span>
                </div>
                
                <p style="margin-top: 20px; color: #718096; font-size: 12px; line-height: 1.5;">Jangan bagikan kode ini kepada siapapun demi keamanan akun Anda.</p>
                <hr style="border: 0; border-top: 1px solid #edf2f7; margin: 25px 0;">
                <p style="font-size: 11px; color: #a0aec0; text-align: center;">© 2026 LapangKu Team</p>
              </div>
            </div>
          </div>
        ''',
      );

      final success = await EmailOTP.sendOTP(email: email);
      if (!mounted) return;
      if (success) {
        setState(() => _isOtpSent = true);
        _startResendTimer();
        SnackbarHelper.showSuccess(context, 'Kode OTP telah dikirim ke $email');
      } else {
        SnackbarHelper.showError(context, 'Gagal mengirim OTP. Coba lagi.');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Error: $e');
    }
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

  void _nextStep() async {
    if (_currentStep == 1) {
      final otpCode = _otpControllers.map((c) => c.text).join();
      if (!_isOtpSent) {
        return SnackbarHelper.showError(
            context, 'Silakan kirim kode OTP terlebih dahulu');
      } else if (otpCode.length != 6) {
        return SnackbarHelper.showError(context, 'Masukkan 6 digit kode OTP');
      } else if (!_isOtpVerified) {
        setState(() => _isSubmitting = true);
        final res = EmailOTP.verifyOTP(otp: otpCode);
        setState(() => _isSubmitting = false);

        if (res) {
          _isOtpVerified = true;
          setState(() => _currentStep++);
          return;
        } else {
          return SnackbarHelper.showError(
              context, 'Kode OTP tidak valid atau sudah kadaluarsa');
        }
      } else {
        setState(() => _currentStep++);
        return;
      }
    } else if (_currentStep == 2) {
      // Validate Profile & Password step
      if (_passwordController.text.length < 8) {
        return SnackbarHelper.showError(context, 'Password minimal 8 karakter');
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        return SnackbarHelper.showError(
            context, 'Konfirmasi password tidak cocok');
      }
    } else if (_currentStep == 3) {
      // Validate Identity step
      if (_ktpPhoto == null) {
        return SnackbarHelper.showError(context, 'Foto KTP wajib diunggah');
      }
      if (_selfiePhoto == null) {
        return SnackbarHelper.showError(context, 'Foto Selfie wajib diunggah');
      }
    } else if (_currentStep == 4) {
      // Validate Field Info step
      if (_ownerNameController.text.trim().isEmpty) {
        return SnackbarHelper.showError(context, 'Nama pemilik wajib diisi');
      }
      if (_phoneController.text.trim().isEmpty) {
        return SnackbarHelper.showError(context, 'Nomor WhatsApp wajib diisi');
      }
      if (_businessNameController.text.trim().isEmpty) {
        return SnackbarHelper.showError(context, 'Nama bisnis wajib diisi');
      }
      if (_fieldNameController.text.trim().isEmpty) {
        return SnackbarHelper.showError(context, 'Nama lapangan wajib diisi');
      }
      if (_selectedSport.isEmpty) {
        return SnackbarHelper.showError(context, 'Pilih jenis olahraga');
      }
    } else if (_currentStep == 5) {
      // Validate Location
      if (_addressController.text.trim().isEmpty) {
        return SnackbarHelper.showError(context, 'Alamat wajib diisi');
      }
    } else if (_currentStep == 6) {
      // Validate Photos
      if (_fieldPhotos.isEmpty) {
        return SnackbarHelper.showError(
            context, 'Unggah minimal satu foto lapangan');
      }
    } else if (_currentStep == 7) {
      // Validate Price & Schedule
      if (_priceController.text.trim().isEmpty) {
        return SnackbarHelper.showError(context, 'Harga sewa wajib diisi');
      }
      if (_selectedDays.isEmpty) {
        return SnackbarHelper.showError(
            context, 'Pilih minimal satu hari operasional');
      }
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
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
    // Capture context-dependent values before async gap
    final jamOperasional = '${_openingTime.format(context)} - ${_closingTime.format(context)}';
    try {
      // 1. Create User in Firebase Auth
      final UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final String newMitraId = credential.user!.uid;
      final mitraService = MitraService();

      // 2. Upload photos in parallel
      final List<Future> uploadTasks = [];

      Future<List<String>> fieldPhotosTask = Future.value([]);
      if (_fieldPhotos.isNotEmpty) {
        fieldPhotosTask =
            mitraService.uploadFieldPhotos(newMitraId, _fieldPhotos);
        uploadTasks.add(fieldPhotosTask);
      }

      Future<String?> ktpTask = Future.value(null);
      if (_ktpPhoto != null) {
        ktpTask = mitraService.uploadDocument(newMitraId, 'ktp', _ktpPhoto!);
        uploadTasks.add(ktpTask);
      }

      Future<String?> selfieTask = Future.value(null);
      if (_selfiePhoto != null) {
        selfieTask =
            mitraService.uploadDocument(newMitraId, 'selfie', _selfiePhoto!);
        uploadTasks.add(selfieTask);
      }

      await Future.wait(uploadTasks);

      final fieldPhotoUrls = await fieldPhotosTask;
      final ktpUrl = await ktpTask;
      final selfieUrl = await selfieTask;

      // 3. Save Data to Firestore
      final db = FirestoreService.instance;

      await Future.wait([
        // Save to 'mitra' collection
        db.collection('mitra').doc(newMitraId).set({
          'uid': newMitraId,
          'email': _emailController.text.trim(),
          'ownerName': _ownerNameController.text.trim(),
          'businessName': _businessNameController.text.trim(),
          'namaBisnis': _businessNameController.text.trim(),
          'mitraName': _ownerNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'isVerified': false,
          'statusVerifikasi': 'menunggu',
          'createdAt': FieldValue.serverTimestamp(),
          'nama_lapangan': _fieldNameController.text.trim(),
          'namaLapangan': _fieldNameController.text.trim(),
          'deskripsi': _fieldDescriptionController.text.trim(),
          'alamat': _addressController.text.trim(),
          'hargaPerJam': int.tryParse(_priceController.text) ?? 0,
          'sport': _selectedSport,
          'jenisLapangan': _selectedSport,
          'tipeLapangan': _selectedFieldType,
          'facilities': _selectedFacilities,
          'fasilitas': _selectedFacilities,
          'jamOperasional': jamOperasional,
          'hariOperasional': _selectedDays,
          'photoUrls': fieldPhotoUrls,
          'ktpUrl': ktpUrl,
          'selfieUrl': selfieUrl,
        }),
        // Save to 'users' collection
        db.collection('users').doc(newMitraId).set({
          'uid': newMitraId,
          'email': _emailController.text.trim(),
          'nama': _businessNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'mitra',
          'isVerified': false,
          'statusVerifikasi': 'menunggu',
          'createdAt': FieldValue.serverTimestamp(),
        }),
        // Save to 'lapangan' collection so the Mitra has an initial field
        db.collection('lapangan').doc().set({
          'mitraId': newMitraId,
          'MitraId': newMitraId, // backward-compat key
          'id_pemilik': newMitraId, // backward-compat key
          'nama_venue': _businessNameController.text.trim(),
          'nama_lapangan': _fieldNameController.text.trim(),
          'jenisLapangan': _selectedSport,
          'kategori_lapangan': _selectedSport,
          'tipe_lapangan': _selectedFieldType,
          'hargaPerJam': int.tryParse(_priceController.text) ?? 0,
          'harga_sewa_jam': int.tryParse(_priceController.text) ?? 0,
          'deskripsi': _fieldDescriptionController.text.trim(),
          'deskripsi_fasilitas': _fieldDescriptionController.text.trim(),
          'alamat': _addressController.text.trim(),
          'alamat_lengkap': _addressController.text.trim(),
          'photoUrls': fieldPhotoUrls,
          'foto_lapangan': fieldPhotoUrls,
          'fasilitas': _selectedFacilities,
          'jamBuka': _openingTime.format(context),
          'jamTutup': _closingTime.format(context),
          'is_aktif':
              true, // Auto-active when registered, or could be false pending verification
          'createdAt': FieldValue.serverTimestamp(),
          'avg_rating': 0.0,
          'total_ulasan': 0,
        }),
      ]);

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Pendaftaran Berhasil! Silakan tunggu verifikasi admin.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MitraWaitingPage()),
          (route) => false,
        );
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
      shape: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2D3748), size: 20),
        onPressed: _isSubmitting ? null : _prevStep,
      ),
      title: const Text('LapangKu',
          style: TextStyle(
              color: Color(0xFF1B6B3A),
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -1.0)),
      centerTitle: true,
      actions: [
        IconButton(
          icon:
              const Icon(Icons.help_outline_rounded, color: Color(0xFF2D3748)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_currentStep == 8) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langkah $_currentStep dari 7',
              style: const TextStyle(
                  color: Color(0xFF1B6B3A),
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                width: (MediaQuery.of(context).size.width - 48) *
                    (_currentStep / 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B6B3A),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Step1Account(
          otpControllers: _otpControllers,
          otpFocusNodes: _otpFocusNodes,
          resendTimer: _resendTimer,
          onResend: _startTimer,
        );
      case 2:
        return Step2Password(
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
        );
      case 3:
        return Step3Identity(
          ktpPhoto: _ktpPhoto,
          selfiePhoto: _selfiePhoto,
          onPickKtp: () => _pickImage(ImageSource.gallery, isKtp: true),
          onPickSelfie: () => _pickImage(ImageSource.camera, isKtp: false),
        );
      case 4:
        return Step4FieldInfo(
          ownerNameController: _ownerNameController,
          businessNameController: _businessNameController,
          whatsappController: _phoneController,
          nameController: _fieldNameController,
          descriptionController: _fieldDescriptionController,
          selectedSport: _selectedSport,
          onSportSelected: (sport) => setState(() => _selectedSport = sport),
          selectedFieldType: _selectedFieldType,
          onFieldTypeSelected: (type) =>
              setState(() => _selectedFieldType = type),
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
      case 5:
        return Step5Location(
          addressController: _addressController,
        );
      case 6:
        return Step6Photos(
          fieldPhotos: _fieldPhotos,
          onPickPhotos: _pickFieldPhotos,
          onRemovePhoto: (index) =>
              setState(() => _fieldPhotos.removeAt(index)),
        );
      case 7:
        return Step7Schedule(
          priceController: _priceController,
          openingTime: _openingTime,
          closingTime: _closingTime,
          selectedDays: _selectedDays,
          selectedFacilities: _selectedFacilities,
          onPickOpeningTime: () async {
            final time = await showTimePicker(
                context: context, initialTime: _openingTime);
            if (time != null) setState(() => _openingTime = time);
          },
          onPickClosingTime: () async {
            final time = await showTimePicker(
                context: context, initialTime: _closingTime);
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
      case 8:
        return Step8Review(
          ownerName: _ownerNameController.text.trim(),
          businessName: _businessNameController.text.trim(),
          email: _emailController.text.trim(),
          contact: _phoneController.text.trim(),
          fieldName: _fieldNameController.text.trim(),
          fieldDescription: _fieldDescriptionController.text.trim(),
          address: _addressController.text.trim(),
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
    final isStep1 = _currentStep == 1;
    final isLastStep = _currentStep == _totalSteps;

    // Logic to disable button in Step 1 if OTP is incomplete
    bool isEnabled = !_isSubmitting;
    if (isStep1) {
      final otpCode = _otpControllers.map((c) => c.text).join();
      if (otpCode.length != 6) {
        isEnabled = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: isEnabled ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF134D2E),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isStep1
                          ? 'Verifikasi'
                          : (isLastStep ? 'Daftar Sekarang' : 'Lanjutkan'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isLastStep
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_ios_rounded,
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
