import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/mitra/field/providers/mitra_field_provider.dart';
import 'package:lapangku/features/mitra/schedule/models/mitra_schedule_model.dart';
import 'package:lapangku/features/mitra/schedule/repositories/mitra_schedule_repository.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

final _MitraSvcForScheduleProvider =
    Provider<MitraService>((ref) => MitraService());

final MitraScheduleRepositoryProvider = Provider<MitraScheduleRepository>(
    (ref) =>
        MitraScheduleRepository(ref.watch(_MitraSvcForScheduleProvider)));

// ── State ──────────────────────────────────────────────────────────
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

// ── Notifier ───────────────────────────────────────────────────────
class MitraScheduleNotifier extends StateNotifier<MitraScheduleState> {
  final MitraScheduleRepository _repository;

  MitraScheduleNotifier(this._repository) : super(const MitraScheduleState());

  Future<void> selectField(String fieldId) async {
    state = state.copyWith(
      selectedFieldId: fieldId,
      schedule: const AsyncLoading(),
    );
    try {
      final schedule = await _repository.getSchedule(fieldId);
      // Sort by day order
      final dayOrder = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
      ];
      schedule.sort((a, b) =>
          dayOrder.indexOf(a.hari).compareTo(dayOrder.indexOf(b.hari)));
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
      await _repository.saveSchedule(fieldId, schedules);
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final mitraScheduleProvider =
    StateNotifierProvider<MitraScheduleNotifier, MitraScheduleState>((ref) {
  final repo = ref.watch(MitraScheduleRepositoryProvider);
  return MitraScheduleNotifier(repo);
});
