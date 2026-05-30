import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Jenis aktivitas keamanan yang dapat dicatat
enum SecurityLogType {
  login,
  passwordChange,
  pinChange,
  deviceLogin,
  emailVerification,
  logout,
}

extension SecurityLogTypeExt on SecurityLogType {
  String get label {
    switch (this) {
      case SecurityLogType.login:
        return 'Login baru terdeteksi';
      case SecurityLogType.passwordChange:
        return 'Password diperbarui';
      case SecurityLogType.pinChange:
        return 'PIN diperbarui';
      case SecurityLogType.deviceLogin:
        return 'Login dari perangkat baru';
      case SecurityLogType.emailVerification:
        return 'Email diverifikasi';
      case SecurityLogType.logout:
        return 'Keluar dari perangkat';
    }
  }

  IconData get icon {
    switch (this) {
      case SecurityLogType.login:
      case SecurityLogType.deviceLogin:
        return Icons.login_rounded;
      case SecurityLogType.passwordChange:
        return Icons.key_rounded;
      case SecurityLogType.pinChange:
        return Icons.pin_rounded;
      case SecurityLogType.emailVerification:
        return Icons.mark_email_read_outlined;
      case SecurityLogType.logout:
        return Icons.logout_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SecurityLogType.login:
      case SecurityLogType.deviceLogin:
        return const Color(0xFF1B6B3A);
      case SecurityLogType.passwordChange:
      case SecurityLogType.pinChange:
        return const Color(0xFF1A65B5);
      case SecurityLogType.emailVerification:
        return const Color(0xFF0D8E65);
      case SecurityLogType.logout:
        return const Color(0xFFB91C1C);
    }
  }

  Color get bgColor {
    switch (this) {
      case SecurityLogType.login:
      case SecurityLogType.deviceLogin:
        return const Color(0xFFE8F5EC);
      case SecurityLogType.passwordChange:
      case SecurityLogType.pinChange:
        return const Color(0xFFEBF4FF);
      case SecurityLogType.emailVerification:
        return const Color(0xFFD1FAE5);
      case SecurityLogType.logout:
        return const Color(0xFFFEE2E2);
    }
  }

  static SecurityLogType fromString(String value) {
    switch (value) {
      case 'login':
        return SecurityLogType.login;
      case 'password_change':
        return SecurityLogType.passwordChange;
      case 'pin_change':
        return SecurityLogType.pinChange;
      case 'device_login':
        return SecurityLogType.deviceLogin;
      case 'email_verification':
        return SecurityLogType.emailVerification;
      case 'logout':
        return SecurityLogType.logout;
      default:
        return SecurityLogType.login;
    }
  }
}

class MitraSecurityLogModel {
  final String id;
  final String mitraId;
  final SecurityLogType type;
  final String deviceName;
  final String location;
  final DateTime timestamp;
  final String details;

  const MitraSecurityLogModel({
    required this.id,
    required this.mitraId,
    required this.type,
    required this.deviceName,
    required this.location,
    required this.timestamp,
    required this.details,
  });

  factory MitraSecurityLogModel.fromMap(Map<String, dynamic> map, String id) {
    return MitraSecurityLogModel(
      id: id,
      mitraId: map['mitraId'] ?? '',
      type: SecurityLogTypeExt.fromString(map['type'] ?? 'login'),
      deviceName: map['deviceName'] ?? 'Perangkat Tidak Dikenal',
      location: map['location'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is Timestamp
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      details: map['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mitraId': mitraId,
      'type': type.name,
      'deviceName': deviceName,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}
