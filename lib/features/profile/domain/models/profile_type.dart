import 'package:flutter/material.dart';

/// Profile type enum for Personal or Company expenses
enum ProfileType {
  personal('personal'),
  company('company');

  const ProfileType(this.value);
  final String value;

  /// Get display name
  String get displayName {
    return switch (this) {
      ProfileType.personal => 'Personal',
      ProfileType.company => 'Company',
    };
  }

  /// Get icon
  String get icon {
    return switch (this) {
      ProfileType.personal => '👤',
      ProfileType.company => '🏢',
    };
  }

  /// Get color
  Color get color {
    return switch (this) {
      ProfileType.personal => const Color(0xFF6366F1), // Indigo
      ProfileType.company => const Color(0xFFEC4899), // Pink
    };
  }

  /// Parse from string
  static ProfileType fromString(String value) {
    return switch (value.toLowerCase()) {
      'personal' => ProfileType.personal,
      'company' => ProfileType.company,
      _ => throw ArgumentError('Invalid profile type: $value'),
    };
  }
}
