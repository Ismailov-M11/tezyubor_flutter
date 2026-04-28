class PharmacyOrder {
  final String id;
  final String token;
  final String status;
  final double medicinesTotal;
  final double? deliveryPrice;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? courierType;
  final String? trackingUrl;
  final String createdAt;
  final String updatedAt;

  const PharmacyOrder({
    required this.id,
    required this.token,
    required this.status,
    required this.medicinesTotal,
    this.deliveryPrice,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.courierType,
    this.trackingUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PharmacyOrder.fromJson(Map<String, dynamic> json) => PharmacyOrder(
        id: json['id']?.toString() ?? '',
        token: json['token'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        medicinesTotal: (json['medicinesTotal'] as num?)?.toDouble() ?? 0,
        deliveryPrice: (json['deliveryPrice'] as num?)?.toDouble(),
        customerName: json['customerName'] as String?,
        customerPhone: json['customerPhone'] as String?,
        customerAddress: json['customerAddress'] as String?,
        courierType: json['courierType'] as String?,
        trackingUrl: json['trackingUrl'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}

class CreateOrderRequest {
  final double medicinesTotal;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  const CreateOrderRequest({
    required this.medicinesTotal,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
  });

  Map<String, dynamic> toJson() => {
        'medicinesTotal': medicinesTotal,
        if (customerName != null) 'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerAddress != null) 'customerAddress': customerAddress,
      };
}
