import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}

final revenueDateRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0)); // This month
});

final mitraRevenueProvider =
    StateNotifierProvider<MitraRevenueNotifier, AsyncValue<MitraRevenueModel>>(
        (ref) {
  final service = ref.watch(mitraServiceProvider);
  final dateRange = ref.watch(revenueDateRangeProvider);
  return MitraRevenueNotifier(service, dateRange);
});

class MitraRevenueNotifier
    extends StateNotifier<AsyncValue<MitraRevenueModel>> {
  final MitraService _service;
  final DateRange _dateRange;

  MitraRevenueNotifier(this._service, this._dateRange)
      : super(const AsyncLoading()) {
    loadRevenue();
  }

  Future<void> loadRevenue() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = AsyncError('Pengguna tidak login', StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    try {
      final revenue =
          await _service.getRevenue(uid, _dateRange.start, _dateRange.end);
      state = AsyncData(revenue);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
