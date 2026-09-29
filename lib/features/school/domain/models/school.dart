import 'package:flutter/foundation.dart';

/// Immutable model representing an educational school organization.
@immutable
class School {
  final String id;
  final String name;
  final String code;
  final String? city;
  final String? country;
  final bool isActive;
  final DateTime createdAt;

  const School({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.country,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'city': city,
      'country': country,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      code: (json['code'] as String).toUpperCase().trim(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is School &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;

  @override
  String toString() => 'School(id: $id, name: $name, code: $code)';
}
