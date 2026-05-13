import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    final text = label ?? labelForL10n(status, context.l10n);
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
            text,
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

  static String labelForL10n(String status, AppL10n l10n) => switch (status) {
        'pending' => l10n.stPending,
        'awaiting_confirmation' => l10n.stAwaiting,
        'confirmed' => l10n.stConfirmed,
        'courier_pickup' => l10n.stPickup,
        'courier_picked' => l10n.stPicked,
        'courier_delivery' => l10n.stDelivery,
        'delivered' => l10n.stDelivered,
        'cancelled' => l10n.stCancelled,
        _ => status,
      };
}
