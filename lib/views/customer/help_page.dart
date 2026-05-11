import 'package:flutter/material.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Booking';
  String _searchQuery = '';

  final List<String> _categories = [
    'Booking',
    'Pembayaran',
    'E-Tiket',
    'Refund',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Booking',
      'question': 'Bagaimana cara booking lapangan?',
      'answer':
          'Pilih lapangan yang Anda inginkan, tentukan tanggal dan jam, lalu tekan tombol "Booking Sekarang". Ikuti langkah pembayaran hingga selesai.',
    },
    {
      'category': 'Pembayaran',
      'question': 'Bagaimana jika pembayaran gagal?',
      'answer':
          'Pastikan saldo Anda mencukupi dan koneksi internet stabil. Jika dana sudah terpotong namun status belum berubah, hubungi Customer Service kami.',
    },
    {
      'category': 'E-Tiket',
      'question': 'Di mana saya melihat e-tiket?',
      'answer':
          'Buka menu "Pesanan Saya" di navigasi bawah. Pilih pesanan yang sudah lunas, dan e-tiket akan muncul di detail pesanan tersebut.',
    },
    {
      'category': 'Refund',
      'question': 'Apakah bisa membatalkan booking?',
      'answer':
          'Pembatalan bisa dilakukan melalui menu detail pesanan. Kebijakan pengembalian dana tergantung pada peraturan masing-masing penyedia lapangan.',
    },
    {
      'category': 'Booking',
      'question': 'Apakah bisa booking untuk minggu depan?',
      'answer':
          'Tentu! Anda bisa memilih tanggal hingga 30 hari ke depan sesuai ketersediaan jadwal lapangan.',
    },
    {
      'category': 'Pembayaran',
      'question': 'Metode pembayaran apa saja yang tersedia?',
      'answer':
          'Kami mendukung pembayaran via Transfer Bank (Virtual Account), E-Wallet (OVO, GoPay, Dana), dan QRIS.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesCategory = faq['category'] == _selectedCategory;
      final matchesSearch = faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH BAR SECTION
            _buildSearchBar(),

            const SizedBox(height: 24),

            // QUICK HELP SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'BANTUAN CEPAT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryChips(),

            const SizedBox(height: 24),

            // FAQ LIST SECTION
            _buildFaqSection(),

            const SizedBox(height: 32),

            // DIRECT HELP SECTION
            _buildDirectHelpSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Cari bantuan atau pertanyaan...',
            hintStyle: TextStyle(color: AppColors.hint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((category) {
          final isActive = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isActive,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive ? AppColors.primary : AppColors.divider,
                ),
              ),
              elevation: 0,
              pressElevation: 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqSection() {
    final filteredFaqs = _filteredFaqs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: filteredFaqs.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFaqs.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(
                          faq['answer']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.hint.withAlpha(128)),
          const SizedBox(height: 16),
          const Text(
            'Pertanyaan tidak ditemukan',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectHelpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUTUH BANTUAN LANGSUNG?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHelpTile(
                  title: 'Hubungi Customer Service',
                  subtitle: 'Respon rata-rata < 5 menit',
                  subtitleColor: AppColors.primary, // Using primary for green
                  icon: Icons.headset_mic_outlined,
                  onTap: () {
                    // Navigate to CS Chat page or perform action
                  },
                ),
                const Divider(height: 1, indent: 60, color: AppColors.divider),
                _buildHelpTile(
                  title: 'Chat via WhatsApp',
                  subtitle: '0812-3456-7890',
                  icon: Icons.chat_outlined,
                  onTap: () => _launchURL('https://wa.me/6281234567890'),
                ),
                const Divider(height: 1, indent: 60, color: AppColors.divider),
                _buildHelpTile(
                  title: 'Email Support',
                  subtitle: 'support@lapangku.id',
                  icon: Icons.email_outlined,
                  onTap: () => _launchURL('mailto:support@lapangku.id'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? subtitleColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor ?? AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
