import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/favorite/favorite_controller.dart';

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
  final bool _isBooking = false;
  late TabController _tabController;
  final List<Map<String, String>> _dates = [];

  // Generate time labels 06:00 - 22:00
  final List<String> _allSlots = List.generate(16, (i) {
    final h = i + 6;
    return '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00';
  });

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateDates();
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
  String _fmt(int h) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(h);
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
      backgroundColor: const Color(0xFF1B6B3A),
      leading: _cBtn(Icons.arrow_back, () => Navigator.pop(context)),
      actions: [
        _cBtn(Icons.share_outlined, () {}),
        _favoriteButton(),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          imgs.isNotEmpty
              ? Image.network(imgs.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
              : _ph(),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black38, Colors.transparent, Colors.black26],
          ))),
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
  Widget _ph() => Container(color: const Color(0xFFE8F5EC), child: const Center(child: Icon(Icons.sports_soccer, size: 60, color: Color(0xFF1B6B3A))));

  // ── BODY ──
  Widget _body() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _headerInfo(), _tabBarW(), _tabContent(), _scheduler(),
          const SizedBox(height: 110),
        ]),
      ),
    );
  }

  // ── HEADER ──
  Widget _headerInfo() {
    final f = widget.field;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(16)),
          child: Text(f.kategori.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
        ),
        const SizedBox(height: 12),
        Text(f.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF718096)),
          const SizedBox(width: 4),
          Expanded(child: Text(f.alamat, style: const TextStyle(fontSize: 13, color: Color(0xFF718096)))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
          const SizedBox(width: 4),
          Text(f.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(' (${f.totalUlasan} ulasan)', style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFE8F5EC), borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 8, color: Color(0xFF1B6B3A)),
              SizedBox(width: 4),
              Text('Buka · 06:00-22:00', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
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
    labelColor: const Color(0xFF1B6B3A), unselectedLabelColor: const Color(0xFF718096),
    indicatorColor: const Color(0xFF1B6B3A), indicatorWeight: 2.5,
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
      Text(_showFullDesc ? desc : (desc.length > 120 ? '${desc.substring(0, 120)}...' : desc),
          style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.6)),
      if (desc.length > 120) GestureDetector(
        onTap: () => setState(() => _showFullDesc = !_showFullDesc),
        child: Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(_showFullDesc ? 'Sembunyikan' : 'Lihat selengkapnya',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A)))),
      ),
      const SizedBox(height: 16),
      _iRow(Icons.attach_money, 'Harga Sewa', '${_fmt(widget.field.hargaPerJam)} / jam'),
      _iRow(Icons.access_time_rounded, 'Jam Operasional', '06:00 - 22:00 WIB'),
    ]));
  }

  Widget _iRow(IconData ic, String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
      child: Icon(ic, size: 18, color: const Color(0xFF1B6B3A))),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
      Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  ]));

  Widget _fasilitasTab() {
    final fas = widget.field.fasilitas.isNotEmpty ? widget.field.fasilitas : ['Parkir Luas', 'Toilet Bersih', 'Mushola', 'Kantin'];
    return Padding(padding: const EdgeInsets.all(20), child: Wrap(spacing: 12, runSpacing: 12, children: fas.map((f) =>
      Container(width: (MediaQuery.of(context).size.width - 52) / 2, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBBF7D0))),
        child: Row(children: [const Icon(Icons.check_circle_outline, color: Color(0xFF1B6B3A), size: 20), const SizedBox(width: 10),
          Expanded(child: Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))]),
      )).toList()));
  }

  Widget _ulasanTab() {
    final f = widget.field;
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Column(children: [
            Text(f.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
            Row(children: List.generate(5, (i) => Icon(i < f.ratingAvg.round() ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 16))),
            Text('${f.totalUlasan} ulasan', style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
          ]),
          const SizedBox(width: 24),
          Expanded(child: Column(children: [_rb('5', 0.65), _rb('4', 0.2), _rb('3', 0.1), _rb('2', 0.03), _rb('1', 0.02)])),
        ])),
      const SizedBox(height: 16),
      _rc('Ahmad R.', 5, 'Lapangan bagus dan terawat!', '2 hari lalu'),
      _rc('Budi S.', 4, 'Tempatnya oke, parkir agak sempit.', '1 minggu lalu'),
    ]));
  }

  Widget _rb(String s, double p) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
    Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF718096))), const SizedBox(width: 8),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: p, backgroundColor: Colors.grey.shade200, color: Colors.amber, minHeight: 6)))]));

  Widget _rc(String n, int s, String t, String time) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(radius: 14, backgroundColor: const Color(0xFF1B6B3A), child: Text(n[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
        const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Row(children: [...List.generate(s, (_) => const Icon(Icons.star_rounded, size: 12, color: Colors.amber)), const SizedBox(width: 6), Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF718096)))])]))]
      ),
      const SizedBox(height: 8),
      Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
    ]));

  Widget _lokasiTab() => Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(height: 160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFE2E8F0)),
      child: const Center(child: Icon(Icons.map_outlined, size: 48, color: Color(0xFF718096)))),
    const SizedBox(height: 12),
    Row(children: [const Icon(Icons.location_on, size: 18, color: Color(0xFF1B6B3A)), const SizedBox(width: 8),
      Expanded(child: Text(widget.field.alamat, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))))]),
  ]));

  // ── SCHEDULER (REAL-TIME) ──
  Widget _scheduler() {
    final bookedAsync = ref.watch(bookedSlotsProvider(_providerKey));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8), const Divider(), const SizedBox(height: 12),
        const Text('PILIH JADWAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748), letterSpacing: 0.5)),
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
                  color: sel ? const Color(0xFF1B6B3A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? const Color(0xFF1B6B3A) : Colors.grey.shade300),
                  boxShadow: sel ? [BoxShadow(color: const Color(0xFF1B6B3A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_dates[i]['day']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white70 : const Color(0xFF718096))),
                  const SizedBox(height: 4),
                  Text(_dates[i]['date']!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sel ? Colors.white : const Color(0xFF2D3748))),
                ]),
              ),
            );
          },
        )),
        const SizedBox(height: 20),
        // Time Slots — real-time dari Firestore
        bookedAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF1B6B3A)))),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Gagal memuat jadwal: $e', style: const TextStyle(color: Colors.red))),
          data: (bookedSlots) {
            return Wrap(spacing: 10, runSpacing: 10,
              children: List.generate(_allSlots.length, (i) {
                final slot = _allSlots[i];
                final isBooked = bookedSlots.contains(slot);
                final isSel = _selectedTimeIndices.contains(i);

                Color bg, border, txt;
                String sub = '';
                if (isBooked) {
                  bg = const Color(0xFFF4F6F9); border = Colors.grey.shade200; txt = Colors.grey.shade400; sub = 'TERPESAN';
                } else if (isSel) {
                  bg = const Color(0xFF1B6B3A); border = const Color(0xFF1B6B3A); txt = Colors.white; sub = 'TERPILIH';
                } else {
                  bg = Colors.white; border = const Color(0xFF1B6B3A); txt = const Color(0xFF1B6B3A);
                }

                return GestureDetector(
                  onTap: isBooked ? null : () => setState(() { isSel ? _selectedTimeIndices.remove(i) : _selectedTimeIndices.add(i); }),
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
          Text(hasSel ? '${_dates[_selectedDateIndex]['full']} · ${_selectedTimeIndices.length} sesi' : 'Pilih jadwal terlebih dahulu',
              style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
          const SizedBox(height: 2),
          Text(hasSel ? _fmt(_totalHarga) : 'Rp -', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
        ])),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: hasSel && !_isBooking ? () => _handleBooking() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6B3A), disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isBooking
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Pesan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

    final selectedSlots = _selectedTimeIndices.map((i) => _allSlots[i]).toList();
    // Sort slots based on original index to maintain order
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
