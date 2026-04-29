class OwnerScheduleModel {
  final String id;
  final String fieldId;
  final String hari; // Senin, Selasa, ..., Minggu
  final String jamBuka; // "08:00"
  final String jamTutup; // "22:00"
  final bool isActive;

  const OwnerScheduleModel({
    required this.id,
    required this.fieldId,
    required this.hari,
    required this.jamBuka,
    required this.jamTutup,
    required this.isActive,
  });

  OwnerScheduleModel copyWith({
    String? id,
    String? fieldId,
    String? hari,
    String? jamBuka,
    String? jamTutup,
    bool? isActive,
  }) {
    return OwnerScheduleModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      hari: hari ?? this.hari,
      jamBuka: jamBuka ?? this.jamBuka,
      jamTutup: jamTutup ?? this.jamTutup,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'hari': hari,
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'isActive': isActive,
    };
  }

  factory OwnerScheduleModel.fromMap(Map<String, dynamic> map, String id) {
    return OwnerScheduleModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      hari: map['hari'] ?? map['day'] ?? '',
      jamBuka: map['jamBuka'] ?? '08:00',
      jamTutup: map['jamTutup'] ?? '22:00',
      isActive: map['isActive'] ?? true,
    );
  }
}
