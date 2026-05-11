import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nama;
  final String role; // customer, mitra, admin
  final String? phone;
  final String? photoUrl;
  final String? avatarUrl;
  final String? bankInfo;
  final bool isVerified;
  final String? jabatan;
  final String? namaBisnis;
  final String? statusVerifikasi; // khusus mitra
  final String? gender;
  final String? city;
  final String? address;
  final String? birthday;
  
  // Security Fields
  final DateTime? lastPasswordChange;
  final bool twoFactorEnabled;
  final bool emailVerified;
  final bool phoneVerified;
  final Map<String, bool> notificationSettings;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    this.phone,
    this.photoUrl,
    this.avatarUrl,
    this.bankInfo,
    this.isVerified = false,
    this.jabatan,
    this.namaBisnis,
    this.statusVerifikasi,
    this.gender,
    this.city,
    this.address,
    this.birthday,
    this.lastPasswordChange,
    this.twoFactorEnabled = false,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.notificationSettings = const {
      'notificationOrder': true,
      'notificationReminder': true,
      'notificationPayment': true,
      'notificationPromo': true,
      'notificationSystem': true,
    },
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    DateTime? lastPwd;
    if (data['lastPasswordChange'] != null) {
      if (data['lastPasswordChange'] is Timestamp) {
        lastPwd = (data['lastPasswordChange'] as Timestamp).toDate();
      } else if (data['lastPasswordChange'] is String) {
        lastPwd = DateTime.tryParse(data['lastPasswordChange']);
      }
    }

    return UserModel(
      uid: data['uid']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      nama: data['nama']?.toString() ?? data['name']?.toString() ?? 'User Tanpa Nama',
      role: data['role']?.toString() ?? 'customer',
      phone: data['phone']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      avatarUrl: data['avatarUrl']?.toString() ?? data['photoUrl']?.toString(),
      bankInfo: data['bankInfo']?.toString(),
      isVerified: data['isVerified'] == true,
      jabatan: data['jabatan']?.toString(),
      namaBisnis: data['namaBisnis']?.toString(),
      statusVerifikasi: data['statusVerifikasi']?.toString() ?? 'proses',
      gender: data['gender']?.toString(),
      city: data['city']?.toString(),
      address: data['address']?.toString(),
      birthday: data['birthday']?.toString(),
      lastPasswordChange: lastPwd,
      twoFactorEnabled: data['twoFactorEnabled'] == true,
      emailVerified: data['emailVerified'] == true,
      phoneVerified: data['phoneVerified'] == true,
      notificationSettings: data['notificationSettings'] != null
          ? Map<String, bool>.from(data['notificationSettings'])
          : {
              'notificationOrder': true,
              'notificationReminder': true,
              'notificationPayment': true,
              'notificationPromo': true,
              'notificationSystem': true,
            },
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'nama': nama,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'avatarUrl': avatarUrl,
      'bankInfo': bankInfo,
      'isVerified': isVerified,
      'jabatan': jabatan,
      'namaBisnis': namaBisnis,
      'statusVerifikasi': statusVerifikasi,
      'gender': gender,
      'city': city,
      'address': address,
      'birthday': birthday,
      'lastPasswordChange': lastPasswordChange != null ? Timestamp.fromDate(lastPasswordChange!) : null,
      'twoFactorEnabled': twoFactorEnabled,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'notificationSettings': notificationSettings,
    };
  }
}
