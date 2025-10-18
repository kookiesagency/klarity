import 'package:flutter/material.dart';
import 'category_type.dart';

/// Category model for expense and income categories
class CategoryModel {
  final String id;
  final String profileId;
  final String name;
  final CategoryType type;
  final String icon;
  final String colorHex;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.icon,
    this.colorHex = '#6366F1', // Default purple color
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String,
      type: CategoryType.fromString(json['type'] as String),
      icon: json['icon'] as String,
      colorHex: json['color_hex'] as String? ?? '#6366F1',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'type': type.value,
      'icon': icon,
      'color_hex': colorHex,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get color from hex
  Color get color {
    try {
      final hexColor = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.purple; // Default color
    }
  }

  /// Copy with
  CategoryModel copyWith({
    String? id,
    String? profileId,
    String? name,
    CategoryType? type,
    String? icon,
    String? colorHex,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: ${type.displayName})';
  }
}

/// Predefined category icons
class CategoryIcons {
  CategoryIcons._();

  static const String housing = '🏠';
  static const String transportation = '🚗';
  static const String food = '🍔';
  static const String utilities = '💡';
  static const String healthcare = '🏥';
  static const String education = '🎓';
  static const String entertainment = '🎬';
  static const String shopping = '👕';
  static const String financial = '💰';
  static const String personal = '🎁';
  static const String communication = '📱';
  static const String travel = '✈️';
  static const String pets = '🐕';
  static const String family = '👨‍👩‍👧‍👦';
  static const String business = '📊';
  static const String creditCard = '💳';
  static const String maintenance = '🔧';
  static const String others = '🎯';

  // Income icons
  static const String salary = '💼';
  static const String businessIncome = '💰';
  static const String investment = '🏦';
  static const String gifts = '🎁';
  static const String refunds = '💵';
  static const String rental = '🏠';
  static const String capitalGains = '📈';
  static const String freelance = '💸';

  static List<String> get allIcons => [
        housing,
        transportation,
        food,
        utilities,
        healthcare,
        education,
        entertainment,
        shopping,
        financial,
        personal,
        communication,
        travel,
        pets,
        family,
        business,
        creditCard,
        maintenance,
        salary,
        businessIncome,
        investment,
        gifts,
        refunds,
        rental,
        capitalGains,
        freelance,
        others,
      ];
}

/// Predefined category colors
class CategoryColors {
  CategoryColors._();

  static const String red = '#EF4444';
  static const String orange = '#F97316';
  static const String yellow = '#EAB308';
  static const String green = '#22C55E';
  static const String blue = '#3B82F6';
  static const String indigo = '#6366F1';
  static const String purple = '#A855F7';
  static const String pink = '#EC4899';
  static const String teal = '#14B8A6';
  static const String cyan = '#06B6D4';

  static List<String> get allColors => [
        red,
        orange,
        yellow,
        green,
        blue,
        indigo,
        purple,
        pink,
        teal,
        cyan,
      ];
}
