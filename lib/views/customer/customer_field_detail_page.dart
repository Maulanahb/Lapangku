import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/favorite/favorite_controller.dart';
import 'package:lapangku/services/firebase/review_service.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';
import 'package:lapangku/standards/widgets/shimmer_loading.dart';
import 'package:lapangku/standards/utils/facility_helper.dart';

class CustomerFieldDetailPage extends ConsumerStatefulWidget {
  final FieldModel field;
  const CustomerFieldDetailPage({super.key, required this.field});

  @override
  ConsumerState<CustomerFieldDetailPage> createState() => _State();
}

class _State extends ConsumerState<CustomerFieldDetailPage> with SingleTickerProviderStateMixin {
  int _selectedDateIndex = 0;
  final Set<int> _selectedTimeIndices = {};

  bool _showFullDesc = false;
  late TabController _tabController;
  final List<Map<String, String>> _dates = [];
  List<String> _allSlots = [];

  void _generateDynamicSlots() {
    int startHour = 8;
    int endHour = 22;

    try {
      startHour = int.parse(widget.field.jamBuka.split(':')[0]);
      endHour = int.parse(widget.field.jamTutup.split(':')[0]);
    } catch (_) {}

    if (endHour <= startHour) {
      endHour += 24;
    }

    final int totalSlots = endHour - startHour;
    _allSlots = List.generate(totalSlots, (i) {
      final h = startHour + i;
      final nextH = h + 1;
      
      final hStr = (h % 24).toString().padLeft(2, '0');
      final nextHStr = (nextH % 24).toString().padLeft(2, '0');
      
      return '$hStr:00 - $nextHStr:00';
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateDates();
    _generateDynamicSlots();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _generateDates() {
    final now = DateTime.now();
    final dayNames = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
    for (int i = 0; i < 7; i++) {
      final d = now.add(Duration(days: i));
      _dates.add({
        'day': dayNames[d.weekday % 7],
        'date': DateFormat('dd').format(d),
        'full': DateFormat('EEEE, dd MMM', 'id_ID').format(d),
        'iso': DateFormat('yyyy-MM-dd').format(d),
      });
    }
  }

  DateTime get _selectedDate => DateTime.parse(_dates[_selectedDateIndex]['iso']!);
  String get _providerKey => '${widget.field.id}|${_dates[_selectedDateIndex]['iso']}';
  // REFAKTOR: sebelumnya String _fmt(int h) => NumberFormat.currency(...).format(h);
  int get _totalHarga => widget.field.hargaPerJam * _selectedTimeIndices.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(slivers: [
        _heroAppBar(),
        SliverToBoxAdapter(child: _body()),
      ]),
      bottomSheet: _bottomBar(),
    );
  }

  // ── HERO ──
  Widget _heroAppBar() {
    final imgs = widget.field.fotoGaleri;
    return SliverAppBar(
      expandedHeight: 280, pinned: true,
      backgroundColor: AppColors.primary, // REFAKTOR: sebelumnya hardcode Color(0xFF1B6B3A)
      leading: _cBtn(Icons.arrow_back, () => Navigator.pop(context)),
      actions: [
        _cBtn(Icons.share_outlined, () {}),
        _favoriteButton(),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          imgs.isNotEmpty
              ? CachedImageWidget(imageUrl: imgs.first, fit: BoxFit.cover, errorWidget: _ph())
              : _ph(),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black38, Colors.transparent, Colors.black26],
          ))),
          Positioned(
            bottom: -1, left: 0, right: 0,
            child: Container(
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _favoriteButton() {
    final favAsync = ref.watch(isFavoritedProvider(widget.field.id));
    final isFav = favAsync.value ?? false;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 18,
        child: IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : Colors.black,
            size: 18,
          ),
          onPressed: () {
            final user = ref.read(authStateProvider).value;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Silakan login terlebih dahulu'), backgroundColor: Colors.red),
              );
              return;
            }
            final service = ref.read(favoriteServiceProvider);
            if (isFav) {
              service.removeFavorite(user.uid, widget.field.id);
            } else {
              service.addFavorite(user.uid, widget.field.id);
            }
          },
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _cBtn(IconData icon, VoidCallback onTap, {Color ic = Colors.black}) => Padding(
    padding: const EdgeInsets.all(8),
    child: CircleAvatar(backgroundColor: Colors.white, radius: 18,
      child: IconButton(icon: Icon(icon, color: ic, size: 18), onPressed: onTap, padding: EdgeInsets.zero)),
  );

  // REFAKTOR: sebelumnya Color(0xFFE8F5EC) dan Color(0xFF1B6B3A)
  Widget _ph() => Container(color: AppColors.primaryLight, child: const Center(child: Icon(Icons.stadium_outlined, size: 60, color: AppColors.primary)));

  Widget _body() {
    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _headerInfo(), _tabBarW(), _tabContent(), _scheduler(),
        const SizedBox(height: 110),
      ]),
    );
  }

  Widget _headerInfo() {
    final f = widget.field;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          // REFAKTOR: sebelumnya Color(0xFFD1FAE5) dan Color(0xFF1B6B3A)
          decoration: BoxDecoration(color: AppColors.statusSuccessBg, borderRadius: BorderRadius.circular(16)),
          child: Text(f.kategori.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        const SizedBox(height: 12),
        if (f.namaVenue.isNotEmpty) ...[
          // REFAKTOR: sebelumnya Color(0xFF718096)
          Text(f.namaVenue.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 4),
        ],
        // REFAKTOR: sebelumnya Color(0xFF2D3748)
        Text(f.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(child: Text(f.alamat, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
          const SizedBox(width: 4),
          Text(f.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(' (${f.totalUlasan} ulasan)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            // REFAKTOR: sebelumnya Color(0xFFE8F5EC) dan Color(0xFF1B6B3A)
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.circle, size: 8, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Buka • ${f.jamBuka}-${f.jamTutup}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── TABS ──
  Widget _tabBarW() => TabBar(
    controller: _tabController, onTap: (_) => setState(() {}),
    // REFAKTOR: sebelumnya hardcode Color(0xFF1B6B3A) dan Color(0xFF718096)
    labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary,
    indicatorColor: AppColors.primary, indicatorWeight: 2.5,
    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    tabs: const [Tab(text: 'Info'), Tab(text: 'Fasilitas'), Tab(text: 'Ulasan'), Tab(text: 'Lokasi')],
  );

  Widget _tabContent() {
    switch (_tabController.index) {
      case 1: return _fasilitasTab();
      case 2: return _ulasanTab();
      case 3: return _lokasiTab();
      default: return _infoTab();
    }
  }

  Widget _infoTab() {
    final desc = widget.field.deskripsi.isNotEmpty ? widget.field.deskripsi
        : '${widget.field.nama} menggunakan rumput sintetis standar internasional yang empuk dan tidak licin. Dilengkapi dengan tribun penonton yang nyaman dan pencahayaan LED.';
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // REFAKTOR: sebelumnya Color(0xFF4A5568)
      Text(_showFullDesc ? desc : (desc.length > 120 ? '${desc.substring(0, 120)}...' : desc),
          style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6)),
      if (desc.length > 120) GestureDetector(
        onTap: () => setState(() => _showFullDesc = !_showFullDesc),
        child: Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(_showFullDesc ? 'Sembunyikan' : 'Lihat selengkapnya',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
      ),
      const SizedBox(height: 16),
      // REFAKTOR: sebelumnya _fmt() — sekarang pakai CurrencyFormatter
      _iRow(Icons.attach_money, 'Harga Sewa', '${CurrencyFormatter.format(widget.field.hargaPerJam)} / jam'),
      _iRow(Icons.access_time_rounded, 'Jam Operasional', '${widget.field.jamBuka} - ${widget.field.jamTutup} WIB'),
    ]));
  }

  Widget _iRow(IconData ic, String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    // REFAKTOR: sebelumnya Color(0xFFF0FDF4) dan Color(0xFF1B6B3A)
    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.backgroundChipGreen, borderRadius: BorderRadius.circular(10)),
      child: Icon(ic, size: 18, color: AppColors.primary)),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  ]));

  Widget _fasilitasTab() {
    final fas = widget.field.fasilitas.isNotEmpty ? widget.field.fasilitas : ['Parkir Luas', 'Toilet Bersih', 'Mushola', 'Kantin'];
    return Padding(padding: const EdgeInsets.all(20), child: Wrap(spacing: 12, runSpacing: 12, children: fas.map((f) =>
      Container(width: (MediaQuery.of(context).size.width - 52) / 2, padding: const EdgeInsets.all(14),
        // REFAKTOR: sebelumnya Color(0xFFF0FDF4) dan Color(0xFFBBF7D0) dan Color(0xFF1B6B3A)
        decoration: BoxDecoration(color: AppColors.backgroundChipGreen, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryBorder)),
        child: Row(children: [Icon(FacilityHelper.getIcon(f), color: AppColors.primary, size: 20), const SizedBox(width: 10),
          Expanded(child: Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))]),
      )).toList()));
  }

  Widget _ulasanTab() {
    final f = widget.field;
    final reviewsAsync = ref.watch(fieldReviewsProvider(f.id));

    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      reviewsAsync.when(
        loading: () => Column(children: [
          _buildSummaryBox(f, 0, 0, 0, 0, 0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, __) => ShimmerLoading.listTile(),
            ),
          ),
        ]),
        error: (e, _) => Column(children: [
          _buildSummaryBox(f, 0, 0, 0, 0, 0),
          Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Gagal memuat ulasan: $e', style: const TextStyle(color: Colors.red)))),
        ]),
        data: (reviews) {
          int c5 = 0, c4 = 0, c3 = 0, c2 = 0, c1 = 0;
          for (var r in reviews) {
            int rating = r['rating'] ?? 5;
            if (rating == 5) {
              c5++;
            } else if (rating == 4) c4++;
            else if (rating == 3) c3++;
            else if (rating == 2) c2++;
            else if (rating == 1) c1++;
          }
          int t = reviews.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryBox(f, t>0?c5/t:0, t>0?c4/t:0, t>0?c3/t:0, t>0?c2/t:0, t>0?c1/t:0),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Belum ada ulasan untuk lapangan ini.', style: TextStyle(color: AppColors.textSecondary)),
                ))
              else
                Column(
                  children: reviews.map((review) {
                    final n = review['userName'] ?? 'Pengguna';
                    final s = review['rating'] ?? 5;
                    final t = review['comment'] ?? '';
                    final reviewImageUrl = review['reviewImageUrl'] ?? '';
                    DateTime date = DateTime.now();
                    if (review['createdAt'] != null) {
                      if (review['createdAt'] is DateTime) {
                        date = review['createdAt'] as DateTime;
                      } else {
                        date = review['createdAt'].toDate();
                      }
                    }
                    final time = DateFormat('dd MMM yyyy').format(date);
                    return _rc(n, s, t, time, reviewImageUrl);
                  }).toList(),
                ),
            ],
          );
        },
      ),
    ]));
  }

  Widget _buildSummaryBox(FieldModel f, double p5, double p4, double p3, double p2, double p1) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.backgroundChipGreen, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Column(children: [
          Text(f.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Row(children: List.generate(5, (i) => Icon(i < f.ratingAvg.round() ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 16))),
          Text('${f.totalUlasan} ulasan', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(width: 24),
        Expanded(child: Column(children: [_rb('5', p5), _rb('4', p4), _rb('3', p3), _rb('2', p2), _rb('1', p1)])),
      ]));
  }

  Widget _rb(String s, double p) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
    Text(s, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)), const SizedBox(width: 8),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: p, backgroundColor: Colors.grey.shade200, color: Colors.amber, minHeight: 6)))]));

  Widget _rc(String n, int s, String t, String time, String reviewImageUrl) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text(n[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
        const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Row(children: [...List.generate(s, (_) => const Icon(Icons.star_rounded, size: 12, color: Colors.amber)), const SizedBox(width: 6),
            Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))])]))]),
      if (t.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
      ],
      if (reviewImageUrl.isNotEmpty) ...[
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedImageWidget(
            imageUrl: reviewImageUrl,
            width: double.infinity,
            height: 140,
            errorWidget: Container(height: 140, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
          ),
        ),
      ],
    ]));

  Widget _lokasiTab() {
    final lat = widget.field.latitude;
    final lng = widget.field.longitude;
    final hasCoordinates = lat != 0.0 && lng != 0.0;

    // OpenStreetMap static tile (gratis, tanpa API key)
    final mapImageUrl = hasCoordinates
        ? 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=600x300&markers=$lat,$lng,red-pushpin'
        : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Peta preview
        GestureDetector(
          onTap: hasCoordinates
              ? () => _openGoogleMaps(lat, lng)
              : null,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.borderLight,
            ),
            clipBehavior: Clip.antiAlias,
            child: mapImageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedImageWidget(
                        imageUrl: mapImageUrl,
                        fit: BoxFit.cover,
                        errorWidget: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text('Gagal memuat peta', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      // Overlay gradient + label
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Ketuk untuk buka di Google Maps',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text('Lokasi peta belum tersedia', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Alamat teks
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.field.alamat.isNotEmpty ? widget.field.alamat : 'Alamat belum diisi',
              style: TextStyle(
                fontSize: 13,
                color: widget.field.alamat.isNotEmpty ? AppColors.textBody : AppColors.textSecondary,
              ),
            ),
          ),
        ]),
        if (hasCoordinates) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openGoogleMaps(lat, lng),
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Buka di Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── SCHEDULER (REAL-TIME) ──
  Widget _scheduler() {
    final bookedAsync = ref.watch(bookedSlotsProvider(_providerKey));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8), const Divider(), const SizedBox(height: 12),
        // REFAKTOR: sebelumnya Color(0xFF2D3748)
        const Text('PILIH JADWAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        // Date Picker
        SizedBox(height: 72, child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: _dates.length,
          itemBuilder: (_, i) {
            final sel = i == _selectedDateIndex;
            return GestureDetector(
              onTap: () => setState(() { _selectedDateIndex = i; _selectedTimeIndices.clear(); }),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 56, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  // REFAKTOR: sebelumnya hardcode Color(0xFF1B6B3A)
                  color: sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300),
                  boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // REFAKTOR: sebelumnya Color(0xFF718096) dan Color(0xFF2D3748)
                  Text(_dates[i]['day']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white70 : AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(_dates[i]['date']!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sel ? Colors.white : AppColors.textDark)),
                ]),
              ),
            );
          },
        )),
        const SizedBox(height: 20),
        // Time Slots – real-time dari Firestore
        bookedAsync.when(
          // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary))),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Gagal memuat jadwal: $e', style: const TextStyle(color: Colors.red))),
          data: (bookedSlots) {
            return Wrap(spacing: 10, runSpacing: 10,
              children: List.generate(_allSlots.length, (i) {
                final slot = _allSlots[i];
                final isBooked = bookedSlots.contains(slot);
                
                // Tambahkan validasi untuk mendisable waktu yang sudah lewat (khusus hari ini)
                bool isPassed = false;
                if (_selectedDateIndex == 0) {
                  final startTimeStr = slot.split(' - ')[0]; // misal "06:00"
                  final parts = startTimeStr.split(':');
                  if (parts.length >= 2) {
                    final hour = int.tryParse(parts[0]) ?? 0;
                    final minute = int.tryParse(parts[1]) ?? 0;
                    final now = DateTime.now();
                    final startDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      hour,
                      minute,
                    );
                    if (now.isAfter(startDateTime)) {
                      isPassed = true;
                    }
                  }
                }
                
                final isUnavailable = isBooked || isPassed;
                final isSel = _selectedTimeIndices.contains(i);

                Color bg, border, txt;
                String sub = '';
                if (isBooked) {
                  bg = AppColors.backgroundPage; border = Colors.grey.shade200; txt = Colors.grey.shade400; sub = 'TERPESAN';
                } else if (isPassed) {
                  bg = AppColors.backgroundPage; border = Colors.grey.shade200; txt = Colors.grey.shade400; sub = 'LEWAT';
                } else if (isSel) {
                  bg = AppColors.primary; border = AppColors.primary; txt = Colors.white; sub = 'TERPILIH';
                } else {
                  bg = Colors.white; border = AppColors.primary; txt = AppColors.primary;
                }

                return GestureDetector(
                  onTap: isUnavailable ? null : () => setState(() { isSel ? _selectedTimeIndices.remove(i) : _selectedTimeIndices.add(i); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.of(context).size.width - 50) / 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Column(children: [
                      Text(slot, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: txt)),
                      if (sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2),
                        child: Text(sub, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isSel ? Colors.white70 : txt.withOpacity(0.7)))),
                    ]),
                  ),
                );
              }),
            );
          },
        ),
      ]),
    );
  }

  // ── BOTTOM BAR ──
  Widget _bottomBar() {
    final hasSel = _selectedTimeIndices.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // REFAKTOR: sebelumnya Color(0xFF718096)
          Text(hasSel ? '${_dates[_selectedDateIndex]['full']} • ${_selectedTimeIndices.length} sesi' : 'Pilih jadwal terlebih dahulu',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          // REFAKTOR: sebelumnya _fmt(_totalHarga) dan Color(0xFF1B6B3A)
          Text(hasSel ? CurrencyFormatter.format(_totalHarga) : 'Rp -', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ])),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: hasSel ? () => _handleBooking() : null,
          style: ElevatedButton.styleFrom(
            // REFAKTOR: sebelumnya Color(0xFF1B6B3A)
            backgroundColor: AppColors.primary, disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Pesan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ]),
    );
  }

  void _handleBooking() {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu'), backgroundColor: Colors.red));
      return;
    }

    final sortedSlots = _selectedTimeIndices.toList()..sort();
    final orderedSlots = sortedSlots.map((i) => _allSlots[i]).toList();

    Navigator.pushNamed(
      context,
      '/booking-confirmation',
      arguments: {
        'field': widget.field,
        'date': _selectedDate,
        'timeSlots': orderedSlots,
      },
    );
  }
}
