import 'package:flutter/material.dart';
import '../../models/auth/user_model.dart';

class NavigationHelper {
  static void navigateByRole(BuildContext context, UserModel user) {
    final route = _getRouteByRole(user);
    
    // Guard: cek mounted sebelum navigate
    if (!context.mounted) return;
    
    Navigator.pushReplacementNamed(context, route);
  }

  static String _getRouteByRole(UserModel user) {
    final role = user.role.toLowerCase().trim();
    
    if (role == 'mitra') {
      final status = (user.statusVerifikasi ?? '').toLowerCase().trim();
      final isAktif = status == 'aktif' || user.isVerified == true;
      
      if (!isAktif) {
        return '/mitra-waiting';
      }
      return '/Mitra-home';
    }
    
    switch (role) {
      case 'admin':
        return '/admin-home';
      case 'customer':
      default:
        return '/customer-home';
    }
  }
}
