import 'package:cloud_firestore/cloud_firestore.dart';

class MitraDeviceModel {
  final String id;
  final String mitraId;
  final String deviceName;
  final String deviceType; // android / ios / web
  final String location;
  final DateTime lastActive;
  final bool isCurrentDevice;
  final String? token;

  const MitraDeviceModel({
    required this.id,
    required this.mitraId,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.lastActive,
    required this.isCurrentDevice,
    this.token,
  });

  factory MitraDeviceModel.fromMap(Map<String, dynamic> map, String id) {
    return MitraDeviceModel(
      id: id,
      mitraId: map['mitraId'] ?? '',
      deviceName: map['deviceName'] ?? 'Perangkat Tidak Dikenal',
      deviceType: map['deviceType'] ?? 'android',
      location: map['location'] ?? 'Tidak Diketahui',
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] is Timestamp
              ? (map['lastActive'] as Timestamp).toDate()
              : DateTime.tryParse(map['lastActive'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isCurrentDevice: map['isCurrentDevice'] ?? false,
      token: map['token'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mitraId': mitraId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'location': location,
      'lastActive': Timestamp.fromDate(lastActive),
      'isCurrentDevice': isCurrentDevice,
      'token': token,
    };
  }
}
