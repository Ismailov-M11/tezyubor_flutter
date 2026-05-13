class PharmacyClient {
  final String id;
  final String phone;
  final String? name;
  final String? lastAddress;
  final int ordersCount;
  final String? lastOrderAt;

  const PharmacyClient({
    required this.id,
    required this.phone,
    this.name,
    this.lastAddress,
    required this.ordersCount,
    this.lastOrderAt,
  });

  factory PharmacyClient.fromJson(Map<String, dynamic> json) => PharmacyClient(
        id: json['id']?.toString() ?? '',
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String?,
        lastAddress: (json['addresses'] as List?)?.whereType<String>().firstOrNull
            ?? json['lastAddress'] as String?,
        ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
        lastOrderAt: json['lastOrderAt'] as String?,
      );
}
