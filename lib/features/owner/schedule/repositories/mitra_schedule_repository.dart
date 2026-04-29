import 'package:lapangku/features/Mitra/schedule/models/Mitra_schedule_model.dart';
import 'package:lapangku/services/firebase/Mitra_service.dart';

class MitraScheduleRepository {
  final MitraService _service;

  MitraScheduleRepository(this._service);

  Future<List<MitraScheduleModel>> getSchedule(String fieldId) =>
      _service.getSchedule(fieldId);

  Future<void> saveSchedule(
          String fieldId, List<MitraScheduleModel> schedules) =>
      _service.saveSchedule(fieldId, schedules);
}
