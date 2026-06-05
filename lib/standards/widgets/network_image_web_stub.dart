import 'package:flutter/material.dart';

/// Stub untuk platform non-web. Gunakan Image.network biasa.
Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
}) {
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
        ),
  );
}
