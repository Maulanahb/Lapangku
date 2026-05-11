import 'package:flutter/material.dart';

class MitraLanguagePage extends StatefulWidget {
  const MitraLanguagePage({super.key});

  @override
  State<MitraLanguagePage> createState() => _MitraLanguagePageState();
}

class _MitraLanguagePageState extends State<MitraLanguagePage> {
  String _selectedLanguage = 'id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Pilih Bahasa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                code: 'id',
                title: 'Bahasa Indonesia',
                flag: '🇮🇩',
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildLanguageOption(
                code: 'en',
                title: 'English',
                flag: '🇬🇧',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({required String code, required String title, required String flag}) {
    final isSelected = _selectedLanguage == code;
    return InkWell(
      onTap: () {
        setState(() => _selectedLanguage = code);
        // Navigate back immediately after selection to feel snappy
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) Navigator.pop(context);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1B6B3A)),
          ],
        ),
      ),
    );
  }
}
