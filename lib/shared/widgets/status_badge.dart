import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final (color, text) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, String) _resolve(String status) => switch (status) {
        'pending' => (AppColors.statusPending, 'Ожидает'),
        'awaiting_confirmation' => (AppColors.statusAwaiting, 'Ожидает подтверждения'),
        'confirmed' => (AppColors.statusConfirmed, 'Подтверждён'),
        'courier_pickup' => (AppColors.statusCourierPickup, 'Курьер едет'),
        'courier_picked' => (AppColors.statusCourierPickup, 'Курьер забрал'),
        'courier_delivery' => (AppColors.statusDelivery, 'Доставка'),
        'delivered' => (AppColors.statusDelivered, 'Доставлен'),
        'cancelled' => (AppColors.statusCancelled, 'Отменён'),
        _ => (AppColors.mutedForegroundLight, status),
      };

  static Color colorFor(String status) => _resolve(status).$1;
  static String labelFor(String status) => _resolve(status).$2;
}
