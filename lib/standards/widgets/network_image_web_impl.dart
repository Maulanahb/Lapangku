// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

int _viewIdCounter = 0;

/// Implementasi web: gunakan <img> HTML tanpa crossorigin agar bebas CORS.
Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
}) {
  // Setiap panggilan mendapat ID unik agar tidak konflik di registry
  final viewId = 'net-img-${url.hashCode}-${_viewIdCounter++}';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final img = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _fitToCSS(fit)
      ..style.display = 'block';
    return img;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}

String _fitToCSS(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
    default:
      return 'contain';
  }
}
