import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Ganti dengan kredensial Cloudinary Anda
  static const String cloudName = "drlgzbypb"; // Placeholder, silakan ganti
  static const String uploadPreset = "Lapangku"; // Placeholder, silakan ganti

  static Future<String?> uploadImage(File file) async {
    try {
      debugPrint('DEBUG CLOUDINARY: Memulai upload file ${file.path}');
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      // Timeout pada pengiriman request
      final response = await request.send().timeout(const Duration(seconds: 30));
      
      // Timeout pada pembacaan stream respon
      final responseData = await response.stream.toBytes().timeout(const Duration(seconds: 15));
      final responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(responseString);
        final secureUrl = jsonMap['secure_url'] as String;
        debugPrint('DEBUG CLOUDINARY: Berhasil! URL: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('DEBUG CLOUDINARY: Gagal! Status: ${response.statusCode}');
        debugPrint('DEBUG CLOUDINARY: Respon Server: $responseString');
        // Lempar error agar ditangkap di catch block MitraRegisterPage
        throw Exception('Cloudinary Upload Failed (${response.statusCode}): $responseString');
      }
    } catch (e) {
      debugPrint('DEBUG CLOUDINARY: Error terjadi: $e');
      rethrow; // Lempar ulang agar ditangkap UI
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> files) async {
    final List<String> results = [];
    for (var file in files) {
      final url = await uploadImage(file);
      if (url != null) {
        results.add(url);
      }
    }
    return results;
  }
}
