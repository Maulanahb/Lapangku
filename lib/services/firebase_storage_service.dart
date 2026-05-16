import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload single image to Firebase Storage
  /// Returns the download URL
  static Future<String?> uploadImage(File file, {String folder = 'uploads'}) async {
    try {
      debugPrint('DEBUG STORAGE: Memulai upload file ${file.path}');
      
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final Reference ref = _storage.ref().child(folder).child(fileName);
      
      final UploadTask uploadTask = ref.putFile(file);
      
      // Monitor progress if needed, but for now just wait for completion
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('DEBUG STORAGE: Berhasil! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('DEBUG STORAGE: Error terjadi: $e');
      rethrow;
    }
  }

  /// Upload multiple images to Firebase Storage
  /// Returns list of download URLs
  static Future<List<String>> uploadMultipleImages(List<File> files, {String folder = 'uploads'}) async {
    final List<String> results = [];
    for (var file in files) {
      final url = await uploadImage(file, folder: folder);
      if (url != null) {
        results.add(url);
      }
    }
    return results;
  }
}
