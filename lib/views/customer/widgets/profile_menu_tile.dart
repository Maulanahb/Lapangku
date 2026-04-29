import 'package:flutter/material.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showDivider;
  final VoidCallback onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.showDivider = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.blueGrey, size: 24),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              : null,
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
      ],
    );
  }
}
