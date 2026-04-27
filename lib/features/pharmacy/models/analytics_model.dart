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
        totalOrders: json['totalOrders'] as int? ?? 0,
        totalMedicines: (json['totalMedicines'] as num?)?.toDouble() ?? 0,
        totalDelivery: (json['totalDelivery'] as num?)?.toDouble() ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        ordersByStatus: Map<String, int>.from(
          (json['ordersByStatus'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ) ??
              {},
        ),
        ordersByCourier: Map<String, int>.from(
          (json['ordersByCourier'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ) ??
              {},
        ),
        ordersByDay: (json['ordersByDay'] as List?)
                ?.map((e) => DailyOrders.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

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
        date: json['date'] as String,
        count: (json['count'] as num).toInt(),
      );
}
