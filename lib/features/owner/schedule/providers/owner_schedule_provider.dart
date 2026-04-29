import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/owner/field/providers/owner_field_provider.dart';
import 'package:lapangku/features/owner/schedule/models/owner_schedule_model.dart';
import 'package:lapangku/features/owner/schedule/repositories/owner_schedule_repository.dart';
import 'package:lapangku/services/firebase/owner_service.dart';

final _ownerSvcForScheduleProvider =
    Provider<OwnerService>((ref) => OwnerService());

final ownerScheduleRepositoryProvider = Provider<OwnerScheduleRepository>(
    (ref) =>
        OwnerScheduleRepository(ref.watch(_ownerSvcForScheduleProvider)));

// ── State ──────────────────────────────────────────────────────────
class OwnerScheduleState {
  final String? selectedFieldId;
  final AsyncValue<List<OwnerScheduleModel>> schedule;
  final bool isSaving;

  const OwnerScheduleState({
    this.selectedFieldId,
    this.schedule = const AsyncLoading(),
    this.isSaving = false,
  });

  OwnerScheduleState copyWith({
    String? selectedFieldId,
    AsyncValue<List<OwnerScheduleModel>>? schedule,
    bool? isSaving,
  }) =>
      OwnerScheduleState(
        selectedFieldId: selectedFieldId ?? this.selectedFieldId,
        schedule: schedule ?? this.schedule,
        isSaving: isSaving ?? this.isSaving,
      );
}

// ── Notifier ───────────────────────────────────────────────────────
class OwnerScheduleNotifier extends StateNotifier<OwnerScheduleState> {
  final OwnerScheduleRepository _repository;

  OwnerScheduleNotifier(this._repository) : super(const OwnerScheduleState());

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
    final updated = List<OwnerScheduleModel>.from(current);
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

final ownerScheduleProvider =
    StateNotifierProvider<OwnerScheduleNotifier, OwnerScheduleState>((ref) {
  final repo = ref.watch(ownerScheduleRepositoryProvider);
  return OwnerScheduleNotifier(repo);
});
