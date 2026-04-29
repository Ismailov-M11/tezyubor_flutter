class AdminOrder {
  final String id;
  final String token;
  final String status;
  final double medicinesTotal;
  final double? deliveryPrice;
  final double? totalPrice;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? selectedCourier;
  final String? trackingUrl;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String? pharmacyPhone;
  final String createdAt;

  const AdminOrder({
    required this.id,
    required this.token,
    required this.status,
    required this.medicinesTotal,
    this.deliveryPrice,
    this.totalPrice,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.selectedCourier,
    this.trackingUrl,
    this.pharmacyName,
    this.pharmacyAddress,
    this.pharmacyPhone,
    required this.createdAt,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
        id: json['id']?.toString() ?? '',
        token: json['token'] as String? ?? '',
        status: json['status'] as String? ?? '',
        medicinesTotal: (json['medicinesTotal'] as num?)?.toDouble() ?? 0,
        deliveryPrice: (json['deliveryPrice'] as num?)?.toDouble(),
        totalPrice: (json['totalPrice'] as num?)?.toDouble(),
        customerName: json['customerName'] as String?,
        customerPhone: json['customerPhone'] as String?,
        customerAddress: json['customerAddress'] as String?,
        selectedCourier: json['selectedCourier'] as String?,
        trackingUrl: json['trackingUrl'] as String?,
        pharmacyName: json['pharmacyName'] as String?,
        pharmacyAddress: json['pharmacyAddress'] as String?,
        pharmacyPhone: json['pharmacyPhone'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class AdminPharmacy {
  final String id;
  final String name;
  final String? ownerName;
  final String login;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActive;
  final String? subscriptionExpiry;
  final String? allowedCouriers;
  final String createdAt;
  final int ordersCount;

  const AdminPharmacy({
    required this.id,
    required this.name,
    this.ownerName,
    required this.login,
    this.email,
    this.phone,
    this.address,
    required this.isActive,
    this.subscriptionExpiry,
    this.allowedCouriers,
    required this.createdAt,
    this.ordersCount = 0,
  });

  factory AdminPharmacy.fromJson(Map<String, dynamic> json) => AdminPharmacy(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        ownerName: json['ownerName'] as String?,
        login: json['login'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        subscriptionExpiry: json['subscriptionExpiry'] as String?,
        allowedCouriers: json['allowedCouriers'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        ordersCount: (json['_count']?['orders'] as num?)?.toInt() ?? 0,
      );
}

class AdminAnalytics {
  final int totalOrders;
  final int activePharmacies;
  final double totalMedicinesAmount;
  final double totalDeliveryAmount;
  final double totalRevenue;
  final List<Map<String, dynamic>> ordersByStatus;
  final List<Map<String, dynamic>> ordersByCourier;
  final List<AdminDailyOrders> ordersByDay;

  const AdminAnalytics({
    required this.totalOrders,
    required this.activePharmacies,
    required this.totalMedicinesAmount,
    required this.totalDeliveryAmount,
    required this.totalRevenue,
    required this.ordersByStatus,
    required this.ordersByCourier,
    required this.ordersByDay,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) =>
      AdminAnalytics(
        totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
        activePharmacies: (json['activePharmacies'] as num?)?.toInt() ?? 0,
        totalMedicinesAmount:
            (json['totalMedicinesAmount'] as num?)?.toDouble() ?? 0,
        totalDeliveryAmount:
            (json['totalDeliveryAmount'] as num?)?.toDouble() ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        ordersByStatus: (json['ordersByStatus'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        ordersByCourier: (json['ordersByCourier'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
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
  final String login;
  final String? phone;
  final bool selfRegistered;
  final String? createdByName;
  final String? createdById;
  final String createdAt;
  final bool isActive;
  final String? subscriptionExpiry;

  const AdminActivation({
    required this.id,
    required this.pharmacyName,
    this.login = '',
    this.phone,
    this.selfRegistered = false,
    this.createdByName,
    this.createdById,
    required this.createdAt,
    required this.isActive,
    this.subscriptionExpiry,
  });

  factory AdminActivation.fromJson(Map<String, dynamic> json) =>
      AdminActivation(
        id: json['id']?.toString() ?? '',
        pharmacyName: json['name'] as String? ?? '',
        login: json['login'] as String? ?? '',
        phone: json['phone'] as String?,
        selfRegistered: json['selfRegistered'] as bool? ?? false,
        createdByName: json['createdBy']?['name'] as String?,
        createdById: json['createdById'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        subscriptionExpiry: json['subscriptionExpiry'] as String?,
      );
}

class AdminActivationStats {
  final int total;
  final int selfRegisteredCount;
  final int superAdminCount;
  final List<Map<String, dynamic>> byUser;

  const AdminActivationStats({
    this.total = 0,
    this.selfRegisteredCount = 0,
    this.superAdminCount = 0,
    this.byUser = const [],
  });

  factory AdminActivationStats.fromJson(Map<String, dynamic> json) =>
      AdminActivationStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        selfRegisteredCount:
            (json['selfRegisteredCount'] as num?)?.toInt() ?? 0,
        superAdminCount: (json['superAdminCount'] as num?)?.toInt() ?? 0,
        byUser: (json['byUser'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
}

class AdminActivationsFilter {
  final String? search;
  final String? creatorType; // 'self', 'superadmin', 'user'
  final String? status; // 'active', 'inactive'
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const AdminActivationsFilter({
    this.search,
    this.creatorType,
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  bool get isActive =>
      (search != null && search!.isNotEmpty) ||
      creatorType != null ||
      status != null ||
      dateFrom != null ||
      dateTo != null;

  AdminActivationsFilter copyWith({
    String? search,
    String? creatorType,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearSearch = false,
    bool clearCreatorType = false,
    bool clearStatus = false,
    bool clearDates = false,
  }) =>
      AdminActivationsFilter(
        search: clearSearch ? null : search ?? this.search,
        creatorType:
            clearCreatorType ? null : creatorType ?? this.creatorType,
        status: clearStatus ? null : status ?? this.status,
        dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
        dateTo: clearDates ? null : dateTo ?? this.dateTo,
      );
}

class AdminRole {
  final String id;
  final String name;
  final List<String> permissions;
  final bool isActive;
  final int usersCount;
  final String createdAt;

  const AdminRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.isActive = true,
    this.usersCount = 0,
    this.createdAt = '',
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) => AdminRole(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        permissions: (json['permissions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        usersCount: (json['_count']?['users'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class AdminClient {
  final String phone;
  final String? name;
  final int ordersCount;
  final String? lastOrderAt;
  final List<String> addresses;
  final List<String> pharmacies;

  const AdminClient({
    required this.phone,
    this.name,
    required this.ordersCount,
    this.lastOrderAt,
    this.addresses = const [],
    this.pharmacies = const [],
  });

  factory AdminClient.fromJson(Map<String, dynamic> json) => AdminClient(
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String?,
        ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
        lastOrderAt: json['lastOrderAt'] as String?,
        addresses: (json['addresses'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        pharmacies: (json['pharmacies'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final bool isActive;
  final List<AdminUserRole> roles;
  final String createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.roles,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        roles: (json['roles'] as List?)
                ?.map(
                    (e) => AdminUserRole.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class AdminUserRole {
  final String id;
  final String name;

  const AdminUserRole({required this.id, required this.name});

  factory AdminUserRole.fromJson(Map<String, dynamic> json) => AdminUserRole(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}
