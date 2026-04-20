import '../../domain/entities/field_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource _datasource;

  AdminRepositoryImpl(this._datasource);

  @override
  Future<AdminStats> getStats() => _datasource.getStats();

  @override
  Future<List<Map<String, dynamic>>> getAllUsers() =>
      _datasource.getAllUsers();

  @override
  Future<List<FieldEntity>> getAllFields() => _datasource.getAllFields();

  @override
  Future<List<BookingEntity>> getAllBookings() =>
      _datasource.getAllBookings();

  @override
  Future<void> updateUserVerifikasi(String uid, String status) =>
      _datasource.updateUserVerifikasi(uid, status);

  @override
  Future<void> updateFieldVerifikasi({
    required String fieldId,
    required String ownerUid,
    required String status,
  }) =>
      _datasource.updateFieldVerifikasi(
        fieldId: fieldId,
        ownerUid: ownerUid,
        status: status,
      );

  @override
  Future<List<int>> getBookingsPerHari() =>
      _datasource.getBookingsPerHari();
}