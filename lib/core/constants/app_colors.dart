import 'package:flutter/material.dart';

class AppColors {
  // Primary orange — unchanged
  static const Color primary = Color(0xFFFF6929);

  // Dark theme (Pulse canvas — cool blue-gray)
  static const Color backgroundDark = Color(0xFF171820);
  static const Color foregroundDark = Color(0xFFF5F6FA);
  static const Color cardDark = Color(0xFF1E2030);
  static const Color borderDark = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color mutedDark = Color(0xFF262840);
  static const Color mutedForegroundDark = Color(0xFF7B7F96);

  // Light theme (clean modern)
  static const Color backgroundLight = Color(0xFFF4F5F7);
  static const Color foregroundLight = Color(0xFF1A1C2A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E4EC);
  static const Color mutedLight = Color(0xFFEEEFF5);
  static const Color mutedForegroundLight = Color(0xFF6E7088);

  // Semantic
  static const Color success = Color(0xFF3DC98A);
  static const Color warning = Color(0xFFF5C842);
  static const Color error = Color(0xFFE55A4A);
  static const Color info = Color(0xFF5BC8E8);

  // Order status colors (vibrant, from design reference)
  static const Color statusPending = Color(0xFFF5C842);      // amber
  static const Color statusAwaiting = Color(0xFF5BC8E8);     // sky blue
  static const Color statusConfirmed = Color(0xFF9B6FE0);    // violet
  static const Color statusCourierPickup = Color(0xFFFF6929); // orange (primary)
  static const Color statusDelivery = Color(0xFF3ECFE0);     // cyan
  static const Color statusDelivered = Color(0xFF3DC98A);    // mint green
  static const Color statusCancelled = Color(0xFFE55A4A);    // rose
}
