class PharmacyProfile {
  final String id;
  final String name;
  final String login;
  final String? email;
  final String? phone;
  final String? address;
  final double? lat;
  final double? lng;
  final bool isActive;
  final String? subscriptionExpiry;
  final bool requiresLocation;

  const PharmacyProfile({
    required this.id,
    required this.name,
    required this.login,
    this.email,
    this.phone,
    this.address,
    this.lat,
    this.lng,
    required this.isActive,
    this.subscriptionExpiry,
    this.requiresLocation = false,
  });

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) =>
      PharmacyProfile(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String,
        login: json['login'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        isActive: json['isActive'] as bool? ?? true,
        subscriptionExpiry: json['subscriptionExpiry'] as String?,
        requiresLocation: json['requiresLocation'] as bool? ?? false,
      );

  bool get isSubscriptionExpiringSoon {
    if (subscriptionExpiry == null) return false;
    final expiry = DateTime.tryParse(subscriptionExpiry!);
    if (expiry == null) return false;
    return expiry.difference(DateTime.now()).inDays <= 14;
  }

  int? get daysUntilExpiry {
    if (subscriptionExpiry == null) return null;
    final expiry = DateTime.tryParse(subscriptionExpiry!);
    if (expiry == null) return null;
    return expiry.difference(DateTime.now()).inDays;
  }
}
