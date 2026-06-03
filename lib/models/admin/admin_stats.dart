class AdminStats {
  final int totalUsers;
  final int lapanganAktif;
  final int pesananHariIni;
  final int totalPendapatan;
  
  // Status counts for the donut/pie chart
  final int countSelesai;
  final int countMenungguBayar;
  final int countMenungguKonfirmasi;
  final int countDikonfirmasi;
  final int countDibatalkan;

  const AdminStats({
    required this.totalUsers,
    required this.lapanganAktif,
    required this.pesananHariIni,
    required this.totalPendapatan,
    required this.countSelesai,
    required this.countMenungguBayar,
    required this.countMenungguKonfirmasi,
    required this.countDikonfirmasi,
    required this.countDibatalkan,
  });
}
