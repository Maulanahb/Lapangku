import 'package:flutter/material.dart';

class FieldFormWidgets {
  static Widget buildSectionHeader(String title, String? subtitle, {Color textGrey = const Color(0xFF6B7280)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A202C))),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 14, color: textGrey)),
        ],
      ],
    );
  }

  static Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1A202C))),
    );
  }

  static Widget buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  static Widget buildPriceField(TextEditingController controller, String hint, {Color textGrey = const Color(0xFF6B7280)}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Text('Rp',
                style:
                    TextStyle(color: textGrey, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildProgressBar({
    required int currentStep,
    required int totalSteps,
    required List<String> labels,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        children: List.generate(labels.length, (index) {
          int step = index + 1;
          bool isLast = index == labels.length - 1;
          return Expanded(
            flex: isLast ? 0 : 1,
            child: Row(
              children: [
                _buildStepNode(step, labels[index], currentStep),
                if (!isLast) _buildStepLine(step, currentStep),
              ],
            ),
          );
        }),
      ),
    );
  }

  static Widget _buildStepNode(int step, String label, int currentStep) {
    bool isCompleted = currentStep > step;
    bool isActive = currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? const Color(0xFF1B6B3A)
                : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(
                    color: const Color(0xFF1B6B3A).withValues(alpha: 0.2),
                    width: 4)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1B6B3A) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  static Widget _buildStepLine(int afterStep, int currentStep) {
    bool isCompleted = currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isCompleted ? const Color(0xFF1B6B3A) : const Color(0xFFF3F4F6),
      ),
    );
  }

  static Widget buildPositionDetector({required VoidCallback onTap}) {
    return Positioned(
      right: 4,
      top: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}

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
