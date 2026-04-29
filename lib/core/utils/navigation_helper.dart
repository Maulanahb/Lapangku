import 'package:flutter/material.dart';
import '../../models/auth/user_model.dart';

class NavigationHelper {
  static void navigateByRole(BuildContext context, UserModel user) {
    final route = _getRouteByRole(user.role);
    
    // Guard: cek mounted sebelum navigate
    if (!context.mounted) return;
    
    Navigator.pushReplacementNamed(context, route);
  }

  static String _getRouteByRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'mitra':
        return '/Mitra-home';
      case 'admin':
        return '/admin-home';
      case 'customer':
      default:
        return '/customer-home'; 
    }
  }
}
