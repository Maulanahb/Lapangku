import 'package:flutter/material.dart';
import 'package:lapangku/standards/models/booking_status.dart';

class StatusBadgeWidget extends StatelessWidget {
  final BookingStatus status;
  final bool isSmall;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.chipLabel, // Menggunakan chipLabel agar tidak terlalu panjang/kaku
        style: TextStyle(
          color: status.color,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
