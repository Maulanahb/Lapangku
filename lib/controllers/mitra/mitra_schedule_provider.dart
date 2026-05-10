import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_schedule_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

// â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MitraScheduleState {
  final String? selectedFieldId;
  final AsyncValue<List<MitraScheduleModel>> schedule;
  final bool isSaving;

  const MitraScheduleState({
    this.selectedFieldId,
    this.schedule = const AsyncLoading(),
    this.isSaving = false,
  });

  MitraScheduleState copyWith({
    String? selectedFieldId,
    AsyncValue<List<MitraScheduleModel>>? schedule,
    bool? isSaving,
  }) =>
      MitraScheduleState(
        selectedFieldId: selectedFieldId ?? this.selectedFieldId,
        schedule: schedule ?? this.schedule,
        isSaving: isSaving ?? this.isSaving,
      );
}

// â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MitraScheduleNotifier extends StateNotifier<MitraScheduleState> {
  final MitraService _service;

  MitraScheduleNotifier(this._service) : super(const MitraScheduleState());

  Future<void> selectField(String fieldId) async {
    state = state.copyWith(
      selectedFieldId: fieldId,
      schedule: const AsyncLoading(),
    );
    try {
      final schedule = await _service.getSchedule(fieldId);
      // Sort by dayOfWeek (1=Senin .. 7=Minggu)
      schedule.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
      state = state.copyWith(schedule: AsyncData(schedule));
    } catch (e, st) {
      state = state.copyWith(schedule: AsyncError(e, st));
    }
  }

  void updateDaySchedule(int index, {String? jamBuka, String? jamTutup, bool? isActive}) {
    final current = state.schedule.value;
    if (current == null) return;
    final updated = List<MitraScheduleModel>.from(current);
    updated[index] = updated[index].copyWith(
      jamBuka: jamBuka,
      jamTutup: jamTutup,
      isActive: isActive,
    );
    state = state.copyWith(schedule: AsyncData(updated));
  }

  Future<void> saveSchedule() async {
    final fieldId = state.selectedFieldId;
    final schedules = state.schedule.value;
    if (fieldId == null || schedules == null) return;

    state = state.copyWith(isSaving: true);
    try {
      await _service.saveSchedule(fieldId, schedules);
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final mitraScheduleProvider =
    StateNotifierProvider<MitraScheduleNotifier, MitraScheduleState>((ref) {
  final service = ref.watch(mitraServiceProvider);
  return MitraScheduleNotifier(service);
});
