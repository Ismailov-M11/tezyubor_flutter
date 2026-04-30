import 'package:flutter/material.dart';

class AppColors {
  // Primary orange — HSL(18, 100%, 58%) = #FF6929
  static const Color primary = Color(0xFFFF6929);

  // Light theme
  static const Color backgroundLight = Color(0xFFF2EFEB);
  static const Color foregroundLight = Color(0xFF1E1A17);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFCBC5BE);
  static const Color mutedLight = Color(0xFFE8E4DF);
  static const Color mutedForegroundLight = Color(0xFF8A7B70);

  // Dark theme
  static const Color backgroundDark = Color(0xFF1A1A17);
  static const Color foregroundDark = Color(0xFFEDEDED);
  static const Color cardDark = Color(0xFF211F1C);
  static const Color borderDark = Color(0xFF373532);
  static const Color mutedDark = Color(0xFF2E2C29);
  static const Color mutedForegroundDark = Color(0xFF8C8880);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Order status colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAwaiting = Color(0xFF3B82F6);
  static const Color statusConfirmed = Color(0xFF8B5CF6);
  static const Color statusCourierPickup = Color(0xFFFF6929);
  static const Color statusDelivery = Color(0xFF0EA5E9);
  static const Color statusDelivered = Color(0xFF22C55E);
  static const Color statusCancelled = Color(0xFFEF4444);
}
