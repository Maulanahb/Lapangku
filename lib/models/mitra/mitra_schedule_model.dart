class MitraScheduleModel {
  final String id;
  final String fieldId;
  final int dayOfWeek; // 1 = Senin, 2 = Selasa, ..., 7 = Minggu
  final String jamBuka; // "08:00"
  final String jamTutup; // "22:00"
  final bool isActive;

  const MitraScheduleModel({
    required this.id,
    required this.fieldId,
    required this.dayOfWeek,
    required this.jamBuka,
    required this.jamTutup,
    required this.isActive,
  });

  /// Mapping nama hari Indonesia ke int dayOfWeek
  static const Map<String, int> _dayNameToInt = {
    'senin': 1,
    'selasa': 2,
    'rabu': 3,
    'kamis': 4,
    'jumat': 5,
    'sabtu': 6,
    'minggu': 7,
  };

  /// Mapping int dayOfWeek ke nama hari Indonesia
  static const Map<int, String> _intToDayName = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    7: 'Minggu',
  };

  /// Backward-compat getter: tetap bisa akses .hari (String)
  String get hari => _intToDayName[dayOfWeek] ?? 'Senin';

  /// Helper: konversi nama hari (String) ke dayOfWeek (int)
  static int parseDayName(String name) {
    return _dayNameToInt[name.toLowerCase().trim()] ?? 1;
  }

  MitraScheduleModel copyWith({
    String? id,
    String? fieldId,
    int? dayOfWeek,
    String? jamBuka,
    String? jamTutup,
    bool? isActive,
  }) {
    return MitraScheduleModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      jamBuka: jamBuka ?? this.jamBuka,
      jamTutup: jamTutup ?? this.jamTutup,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'dayOfWeek': dayOfWeek,
      'hari': hari, // backward-compat: tulis juga nama hari string
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'isActive': isActive,
    };
  }

  factory MitraScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    // Prioritas: baca dayOfWeek (int), fallback parsing dari string hari
    int day;
    if (map['dayOfWeek'] != null && map['dayOfWeek'] is int) {
      day = map['dayOfWeek'] as int;
    } else if (map['hari'] != null && map['hari'] is String) {
      day = parseDayName(map['hari'] as String);
    } else if (map['day'] != null && map['day'] is String) {
      day = parseDayName(map['day'] as String);
    } else {
      day = 1; // default Senin
    }

    return MitraScheduleModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      dayOfWeek: day,
      jamBuka: map['jamBuka'] ?? '08:00',
      jamTutup: map['jamTutup'] ?? '22:00',
      isActive: map['isActive'] ?? true,
    );
  }
}
