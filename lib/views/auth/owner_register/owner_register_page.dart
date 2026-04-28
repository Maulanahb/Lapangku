import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lapangku/views/owner/owner_main_page.dart';

// Import Langkah-langkah (Sekarang satu folder)
import 'step1_account.dart';
import 'step2_identity.dart';
import 'step3_field_info.dart';
import 'step4_location.dart';
import 'step5_photos.dart';
import 'step6_schedule.dart';
import 'step7_review.dart';

class OwnerRegisterPage extends StatefulWidget {
  const OwnerRegisterPage({super.key});

  @override
  State<OwnerRegisterPage> createState() => _OwnerRegisterPageState();
}

class _OwnerRegisterPageState extends State<OwnerRegisterPage> {
  int _currentStep = 1;
  final int _totalSteps = 7;

  // Controllers & State
  final _contactController = TextEditingController();
  final _fieldNameController = TextEditingController();
  final _fieldDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedSport = 'Futsal';
  List<String> _selectedFacilities = ['Parkir', 'Wifi', 'Mushola'];
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  List<String> _selectedDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  int _resendTimer = 60;
  Timer? _timer;

  // Foto
  File? _ktpPhoto;
  File? _selfiePhoto;
  List<File> _fieldPhotos = [];
  final ImagePicker _picker = ImagePicker();

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

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _contactController.dispose();
    _fieldNameController.dispose();
    _fieldDescriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _nextStep() {
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

  void _submitRegistration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B6B3A)),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OwnerMainPage()),
        (route) => false,
      );
    });
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
        onPressed: _prevStep,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Color(0xFF2D3748)),
          onPressed: () {},
        ),
      ],
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
              fontSize: 12,
            ),
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
          otpControllers: _otpControllers,
          otpFocusNodes: _otpFocusNodes,
          resendTimer: _resendTimer,
          onResend: _startTimer,
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
        return Step4Location(
          addressController: _addressController,
        );
      case 5:
        return Step5Photos(
          fieldPhotos: _fieldPhotos,
          onPickPhotos: _pickFieldPhotos,
          onRemovePhoto: (index) {
            setState(() {
              _fieldPhotos.removeAt(index);
            });
          },
        );
      case 6:
        return Step6Schedule(
          priceController: _priceController,
          openingTime: _openingTime,
          closingTime: _closingTime,
          selectedDays: _selectedDays,
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
        );
      case 7:
        return Step7Review(
          contact: _contactController.text,
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
    bool isStep1 = _currentStep == 1;
    bool isLastStep = _currentStep == _totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F5A2F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isStep1 ? 'Verifikasi' : (isLastStep ? 'Selesai' : 'Lanjutkan'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!isStep1) ...[
                const SizedBox(width: 8),
                Icon(isLastStep ? Icons.check_circle : Icons.arrow_forward,
                    color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
