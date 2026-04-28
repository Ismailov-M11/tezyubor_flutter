class PharmacyAnalytics {
  final int totalOrders;
  final double totalMedicines;
  final double totalDelivery;
  final double totalRevenue;
  final Map<String, int> ordersByStatus;
  final Map<String, int> ordersByCourier;
  final List<DailyOrders> ordersByDay;

  const PharmacyAnalytics({
    required this.totalOrders,
    required this.totalMedicines,
    required this.totalDelivery,
    required this.totalRevenue,
    required this.ordersByStatus,
    required this.ordersByCourier,
    required this.ordersByDay,
  });

  factory PharmacyAnalytics.fromJson(Map<String, dynamic> json) =>
      PharmacyAnalytics(
        totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
        totalMedicines:
            ((json['totalMedicinesAmount'] ?? json['totalMedicines']) as num?)
                    ?.toDouble() ??
                0,
        totalDelivery:
            ((json['totalDeliveryAmount'] ?? json['totalDelivery']) as num?)
                    ?.toDouble() ??
                0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        ordersByStatus: _toMap(json['ordersByStatus'], 'status', 'count'),
        ordersByCourier: _toMap(json['ordersByCourier'], 'courier', 'count'),
        ordersByDay: (json['ordersByDay'] as List?)
                ?.map((e) => DailyOrders.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static Map<String, int> _toMap(dynamic raw, String key, String value) {
    if (raw is Map) {
      return Map<String, int>.from(
        raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      );
    }
    if (raw is List) {
      return Map.fromEntries(
        raw.map((e) {
          final m = e as Map;
          return MapEntry(
            m[key]?.toString() ?? '',
            (m[value] as num?)?.toInt() ?? 0,
          );
        }),
      );
    }
    return {};
  }

  factory PharmacyAnalytics.empty() => const PharmacyAnalytics(
        totalOrders: 0,
        totalMedicines: 0,
        totalDelivery: 0,
        totalRevenue: 0,
        ordersByStatus: {},
        ordersByCourier: {},
        ordersByDay: [],
      );
}

class DailyOrders {
  final String date;
  final int count;

  const DailyOrders({required this.date, required this.count});

  factory DailyOrders.fromJson(Map<String, dynamic> json) => DailyOrders(
        date: json['date'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
