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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? text,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
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
