class BookingModel {
  final String bookingId;
  final String namaLapangan;
  final String namaPenyewa;
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final int totalHarga;
  final String status;

  const BookingModel({
    required this.bookingId,
    required this.namaLapangan,
    required this.namaPenyewa,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.totalHarga,
    required this.status,
  });
}
