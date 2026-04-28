class AdminOrder {
  final String id;
  final String token;
  final String status;
  final double medicinesTotal;
  final double? deliveryPrice;
  final String? customerName;
  final String? customerPhone;
  final String? courierType;
  final String createdAt;
  final AdminPharmacyRef? pharmacy;

  const AdminOrder({
    required this.id,
    required this.token,
    required this.status,
    required this.medicinesTotal,
    this.deliveryPrice,
    this.customerName,
    this.customerPhone,
    this.courierType,
    required this.createdAt,
    this.pharmacy,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
        id: json['id']?.toString() ?? '',
        token: json['token'] as String? ?? '',
        status: json['status'] as String? ?? '',
        medicinesTotal: (json['medicinesTotal'] as num?)?.toDouble() ?? 0,
        deliveryPrice: json['deliveryPrice'] != null
            ? (json['deliveryPrice'] as num).toDouble()
            : null,
        customerName: json['customerName'] as String?,
        customerPhone: json['customerPhone'] as String?,
        courierType: json['courierType'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        pharmacy: json['pharmacy'] != null
            ? AdminPharmacyRef.fromJson(
                json['pharmacy'] as Map<String, dynamic>)
            : null,
      );
}

class AdminPharmacyRef {
  final String id;
  final String name;

  const AdminPharmacyRef({required this.id, required this.name});

  factory AdminPharmacyRef.fromJson(Map<String, dynamic> json) =>
      AdminPharmacyRef(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class AdminPharmacy {
  final String id;
  final String name;
  final String login;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActive;
  final String? subscriptionExpiry;
  final String createdAt;
  final int ordersCount;

  const AdminPharmacy({
    required this.id,
    required this.name,
    required this.login,
    this.email,
    this.phone,
    this.address,
    required this.isActive,
    this.subscriptionExpiry,
    required this.createdAt,
    this.ordersCount = 0,
  });

  factory AdminPharmacy.fromJson(Map<String, dynamic> json) => AdminPharmacy(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        login: json['login'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        subscriptionExpiry: json['subscriptionExpiry'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        ordersCount: (json['_count']?['orders'] as num?)?.toInt() ?? 0,
      );
}

class AdminAnalytics {
  final int totalOrders;
  final int totalPharmacies;
  final double totalRevenue;
  final Map<String, int> ordersByStatus;
  final Map<String, int> ordersByCourier;
  final List<AdminDailyOrders> ordersByDay;

  const AdminAnalytics({
    required this.totalOrders,
    required this.totalPharmacies,
    required this.totalRevenue,
    required this.ordersByStatus,
    required this.ordersByCourier,
    required this.ordersByDay,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) => AdminAnalytics(
        totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
        totalPharmacies: (json['totalPharmacies'] as num?)?.toInt() ?? 0,
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
                ?.map((e) =>
                    AdminDailyOrders.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AdminDailyOrders {
  final String date;
  final int count;

  const AdminDailyOrders({required this.date, required this.count});

  factory AdminDailyOrders.fromJson(Map<String, dynamic> json) =>
      AdminDailyOrders(
        date: json['date'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class AdminActivation {
  final String id;
  final String pharmacyName;
  final String? createdByName;
  final String createdAt;
  final bool isActive;

  const AdminActivation({
    required this.id,
    required this.pharmacyName,
    this.createdByName,
    required this.createdAt,
    required this.isActive,
  });

  factory AdminActivation.fromJson(Map<String, dynamic> json) =>
      AdminActivation(
        id: json['id']?.toString() ?? '',
        pharmacyName: json['name'] as String? ?? '',
        createdByName: json['createdBy']?['name'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
}

class AdminRole {
  final String id;
  final String name;
  final List<String> permissions;

  const AdminRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) => AdminRole(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        permissions: (json['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class AdminClient {
  final String id;
  final String phone;
  final String? name;
  final int ordersCount;
  final String? lastOrderAt;

  const AdminClient({
    required this.id,
    required this.phone,
    this.name,
    required this.ordersCount,
    this.lastOrderAt,
  });

  factory AdminClient.fromJson(Map<String, dynamic> json) => AdminClient(
        id: json['id']?.toString() ?? '',
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String?,
        ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
        lastOrderAt: json['lastOrderAt'] as String?,
      );
}
