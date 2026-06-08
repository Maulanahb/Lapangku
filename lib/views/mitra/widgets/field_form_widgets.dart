import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Daftar fasilitas yang digunakan oleh AddFieldPage dan EditFieldPage.
const List<Map<String, dynamic>> facilitiesList = [
  {'name': 'Parkir', 'icon': Icons.local_parking},
  {'name': 'Toilet', 'icon': Icons.wc},
  {'name': 'Wifi', 'icon': Icons.wifi},
  {'name': 'CCTV', 'icon': Icons.videocam_outlined},
  {'name': 'Mushola', 'icon': Icons.mosque_outlined},
  {'name': 'Kantin', 'icon': Icons.restaurant},
  {'name': 'Ruang Ganti', 'icon': Icons.checkroom},
  {'name': 'Tribun', 'icon': Icons.stadium_outlined},
];

/// Kumpulan widget helper statis untuk form lapangan (Add/Edit Field).
class FieldFormWidgets {
  FieldFormWidgets._(); // Prevent instantiation

  // --- Progress Bar ---
  static Widget buildProgressBar({
    required int currentStep,
    required int totalSteps,
    required List<String> labels,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Garis penghubung
            final stepIndex = i ~/ 2;
            final isActive = (stepIndex + 1) < currentStep;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 13), // 28/2 = 14 (approx center)
                height: 2,
                color: isActive
                    ? const Color(0xFF0F5A3C)
                    : const Color(0xFFE2E8F0),
              ),
            );
          } else {
            // Lingkaran dan teks
            final stepIndex = i ~/ 2;
            final stepNum = stepIndex + 1;
            final isActive = stepNum <= currentStep;
            return SizedBox(
              width: 85, // Menjaga teks tetap rapi dan terpusat dengan lingkaran
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0F5A3C)
                          : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isActive && stepNum < currentStep
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : Text(
                              '$stepNum',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[stepIndex],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF0F5A3C)
                          : const Color(0xFF9CA3AF),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }

  // --- Section Header ---
  static Widget buildSectionHeader(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F5A3C),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  // --- Label ---
  static Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A202C),
        ),
      ),
    );
  }

  // --- Text Field ---
  static Widget buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: readOnly ? const Color(0xFF718096) : const Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // --- Price Field ---
  static Widget buildPriceField(
    TextEditingController controller,
    String hint,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          prefixText: 'Rp ',
          prefixStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F5A3C),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // --- Delete Button (Positioned) ---
  static Widget buildPositionDetector({required VoidCallback onTap}) {
    return Positioned(
      right: 8,
      top: 8,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
