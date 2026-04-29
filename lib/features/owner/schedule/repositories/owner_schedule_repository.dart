import 'package:lapangku/features/owner/schedule/models/owner_schedule_model.dart';
import 'package:lapangku/services/firebase/owner_service.dart';

class OwnerScheduleRepository {
  final OwnerService _service;

  OwnerScheduleRepository(this._service);

  Future<List<OwnerScheduleModel>> getSchedule(String fieldId) =>
      _service.getSchedule(fieldId);

  Future<void> saveSchedule(
          String fieldId, List<OwnerScheduleModel> schedules) =>
      _service.saveSchedule(fieldId, schedules);
}
