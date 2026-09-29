import 'package:flutter/foundation.dart';

/// Immutable authenticated user model.
@immutable
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ fullName.hashCode;

  @override
  String toString() => 'AuthUser(id: $id, email: $email, fullName: $fullName)';
}
