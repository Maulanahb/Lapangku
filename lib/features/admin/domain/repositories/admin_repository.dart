import '../entities/field_entity.dart';
import '../entities/booking_entity.dart';
import '../../data/datasources/admin_remote_datasource.dart';

abstract class AdminRepository {
  Future<AdminStats> getStats();
  Future<List<Map<String, dynamic>>> getAllUsers();
  Future<List<FieldEntity>> getAllFields();
  Future<List<BookingEntity>> getAllBookings();
  Future<void> updateUserVerifikasi(String uid, String status);
  Future<void> updateFieldVerifikasi({
    required String fieldId,
    required String ownerUid,
    required String status,
  });
  Future<List<int>> getBookingsPerHari();
}