import 'dart:io';
import 'package:lapangku/services/cloudinary_service.dart';

void main() async {
  final file = File('assets/images/dummyInvoice.jpeg');
  if (!file.existsSync()) {
    print('File not found at ${file.path}');
    exit(1);
  }
  print('Uploading image...');
  try {
    final url = await CloudinaryService.uploadImage(file);
    print('SUCCESS_URL=$url');
  } catch (e) {
    print('Error: $e');
  }
}
