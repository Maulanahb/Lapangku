import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Pre-defined skeletons
  
  static Widget card({double height = 200}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ShimmerLoading(width: double.infinity, height: height, borderRadius: 16),
    );
  }

  static Widget listTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 80, height: 80, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 120, height: 14),
                const SizedBox(height: 12),
                const ShimmerLoading(width: 80, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget avatar({double size = 50}) {
    return ShimmerLoading(width: size, height: size, borderRadius: size / 2);
  }
}
