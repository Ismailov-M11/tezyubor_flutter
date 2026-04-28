class PharmacyOrder {
  final String id;
  final String token;
  final String status;
  final String? pharmacyComment;
  final double? medicinesTotal;
  final double? deliveryPrice;
  final double? totalPrice;
  final String? orderUrl;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerComment;
  final String? courierType;
  final String? trackingUrl;
  final String createdAt;
  final String updatedAt;

  const PharmacyOrder({
    required this.id,
    required this.token,
    required this.status,
    this.pharmacyComment,
    this.medicinesTotal,
    this.deliveryPrice,
    this.totalPrice,
    this.orderUrl,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerComment,
    this.courierType,
    this.trackingUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PharmacyOrder.fromJson(Map<String, dynamic> json) => PharmacyOrder(
        id: json['id']?.toString() ?? '',
        token: json['token'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        pharmacyComment: json['pharmacyComment'] as String?,
        medicinesTotal: (json['medicinesTotal'] as num?)?.toDouble(),
        deliveryPrice: (json['deliveryPrice'] as num?)?.toDouble(),
        totalPrice: (json['totalPrice'] as num?)?.toDouble(),
        orderUrl: json['orderUrl'] as String?,
        customerName: json['customerName'] as String?,
        customerPhone: json['customerPhone'] as String?,
        customerAddress: json['customerAddress'] as String?,
        customerComment: json['customerComment'] as String?,
        courierType: json['courierType'] as String?,
        trackingUrl: json['trackingUrl'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}

class CreateOrderRequest {
  final String pharmacyComment;
  final double? medicinesTotal;
  final String? customerName;
  final String? customerPhone;

  const CreateOrderRequest({
    required this.pharmacyComment,
    this.medicinesTotal,
    this.customerName,
    this.customerPhone,
  });

  Map<String, dynamic> toJson() => {
        'pharmacyComment': pharmacyComment,
        if (medicinesTotal != null) 'medicinesTotal': medicinesTotal,
        if (customerName != null) 'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
      };
}
