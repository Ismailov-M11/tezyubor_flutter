import 'dart:convert';

enum AppEnvironment { app, admin }

enum UserRole { pharmacy, admin }

class AuthUser {
  final String id;
  final String name;
  final String? email;
  final String? login;
  final UserRole role;
  final List<String> permissions;
  final bool isSuperAdmin;
  final String? subscriptionExpiry;
  final bool requiresLocation;

  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.login,
    required this.role,
    this.permissions = const [],
    this.isSuperAdmin = false,
    this.subscriptionExpiry,
    this.requiresLocation = false,
  });

  bool hasPermission(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'pharmacy';
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      login: json['login'] as String?,
      role: roleStr == 'admin' || roleStr == 'admin_user'
          ? UserRole.admin
          : UserRole.pharmacy,
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
      subscriptionExpiry: json['subscriptionExpiry'] as String?,
      requiresLocation: json['requiresLocation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'login': login,
        'role': role == UserRole.admin ? 'admin' : 'pharmacy',
        'permissions': permissions,
        'isSuperAdmin': isSuperAdmin,
        'subscriptionExpiry': subscriptionExpiry,
        'requiresLocation': requiresLocation,
      };

  String toJsonString() => jsonEncode(toJson());

  static AuthUser? fromJsonString(String? str) {
    if (str == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class AuthState {
  final String? token;
  final AuthUser? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    String? token,
    AuthUser? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearError = false,
    bool clearToken = false,
    bool clearUser = false,
  }) =>
      AuthState(
        token: clearToken ? null : token ?? this.token,
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}
