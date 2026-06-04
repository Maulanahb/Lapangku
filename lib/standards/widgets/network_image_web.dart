import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Kondisional import: gunakan implementasi web hanya di platform web
import 'network_image_web_stub.dart'
    if (dart.library.html) 'network_image_web_impl.dart' as impl;

/// Widget gambar yang melewati masalah CORS di Flutter Web.
/// Di platform non-web, fallback ke [Image.network] biasa.
class WebSafeNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const WebSafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return impl.buildWebImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
    );
  }
}
