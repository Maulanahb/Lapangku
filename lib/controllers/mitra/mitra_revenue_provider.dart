import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}

final revenueDateRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(
    DateTime(now.year, now.month, now.day),
    DateTime(now.year, now.month, now.day, 23, 59, 59),
  ); // Today
});

final mitraRevenueProvider =
    StateNotifierProvider<MitraRevenueNotifier, AsyncValue<MitraRevenueModel>>(
        (ref) {
  final service = ref.watch(mitraServiceProvider);
  final uid = ref.watch(currentUidProvider);
  
  return MitraRevenueNotifier(service, ref, uid);
});

class MitraRevenueNotifier
    extends StateNotifier<AsyncValue<MitraRevenueModel>> {
  final MitraService _service;
  final Ref _ref;
  final String _uid;

  MitraRevenueNotifier(this._service, this._ref, this._uid)
      : super(const AsyncLoading()) {
    final initialRange = _ref.read(revenueDateRangeProvider);
    loadRevenue(initialRange);
  }

  Future<void> loadRevenue([DateRange? range]) async {
    if (_uid.isEmpty) {
      state = AsyncError('Pengguna tidak login', StackTrace.current);
      return;
    }

    final previousState = state;
    if (previousState.hasValue) {
      state = AsyncValue<MitraRevenueModel>.loading().copyWithPrevious(previousState);
    } else {
      state = const AsyncLoading();
    }

    try {
      final targetRange = (range ?? _ref.read(revenueDateRangeProvider))!;
      final revenue =
          await _service.getRevenue(_uid, targetRange.start, targetRange.end);
      state = AsyncData(revenue);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
