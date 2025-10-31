import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/category_type.dart';

/// Repository for category operations
class CategoryRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all categories for current profile
  Future<Result<List<CategoryModel>>> getCategories(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.categoriesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('name', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      return Success(categories);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get categories by type for current profile
  Future<Result<List<CategoryModel>>> getCategoriesByType({
    required String profileId,
    required CategoryType type,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.categoriesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('type', type.value)
          .eq('is_active', true)
          .order('name', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      return Success(categories);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get category by ID
  Future<Result<CategoryModel>> getCategoryById(String categoryId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.categoriesTable)
          .select()
          .eq('id', categoryId)
          .single();

      final category = CategoryModel.fromJson(response);
      return Success(category);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new category
  Future<Result<CategoryModel>> createCategory({
    required String profileId,
    required String name,
    required CategoryType type,
    required String icon,
    required String colorHex,
    bool isDefault = false,
  }) async {
    try {
      // Check if category with same name exists but is inactive
      final existingResponse = await _supabase
          .from(ApiConstants.categoriesTable)
          .select()
          .eq('profile_id', profileId)
          .eq('name', name)
          .eq('type', type.value)
          .maybeSingle();

      // If inactive category exists, reactivate it with new icon/color
      if (existingResponse != null) {
        final existingCategory = CategoryModel.fromJson(existingResponse);

        // Reactivate and update the existing category
        final reactivatedResponse = await _supabase
            .from(ApiConstants.categoriesTable)
            .update({
              'is_active': true,
              'icon': icon,
              'color_hex': colorHex,
              'is_default': isDefault,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingCategory.id)
            .select()
            .single();

        final category = CategoryModel.fromJson(reactivatedResponse);
        return Success(category);
      }

      // If no existing category, create new one
      final response = await _supabase
          .from(ApiConstants.categoriesTable)
          .insert({
            'profile_id': profileId,
            'name': name,
            'type': type.value,
            'icon': icon,
            'color_hex': colorHex,
            'is_default': isDefault,
            'is_active': true,
          })
          .select()
          .single();

      final category = CategoryModel.fromJson(response);
      return Success(category);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Update category
  Future<Result<CategoryModel>> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? colorHex,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (icon != null) updates['icon'] = icon;
      if (colorHex != null) updates['color_hex'] = colorHex;
      if (isActive != null) updates['is_active'] = isActive;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(ApiConstants.categoriesTable)
          .update(updates)
          .eq('id', categoryId)
          .select()
          .single();

      final category = CategoryModel.fromJson(response);
      return Success(category);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete category (soft delete by setting is_active to false)
  Future<Result<void>> deleteCategory(String categoryId) async {
    try {
      await _supabase
          .from(ApiConstants.categoriesTable)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Hard delete category (permanently remove from database)
  Future<Result<void>> hardDeleteCategory(String categoryId) async {
    try {
      await _supabase
          .from(ApiConstants.categoriesTable)
          .delete()
          .eq('id', categoryId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create default categories for new profile
  Future<Result<List<CategoryModel>>> createDefaultCategories(String profileId) async {
    try {
      // Default expense categories
      final expenseCategories = [
        {
          'profile_id': profileId,
          'name': 'Food & Dining',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.food,
          'color_hex': CategoryColors.orange,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Transportation',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.transportation,
          'color_hex': CategoryColors.blue,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Shopping',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.shopping,
          'color_hex': CategoryColors.pink,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Entertainment',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.entertainment,
          'color_hex': CategoryColors.purple,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Utilities',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.utilities,
          'color_hex': CategoryColors.yellow,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Healthcare',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.healthcare,
          'color_hex': CategoryColors.red,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Education',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.education,
          'color_hex': CategoryColors.indigo,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Housing',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.housing,
          'color_hex': CategoryColors.green,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Personal Care',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.personal,
          'color_hex': CategoryColors.cyan,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Others',
          'type': CategoryType.expense.value,
          'icon': CategoryIcons.others,
          'color_hex': CategoryColors.teal,
          'is_default': true,
          'is_active': true,
        },
      ];

      // Default income categories
      final incomeCategories = [
        {
          'profile_id': profileId,
          'name': 'Salary',
          'type': CategoryType.income.value,
          'icon': CategoryIcons.salary,
          'color_hex': CategoryColors.green,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Business Income',
          'type': CategoryType.income.value,
          'icon': CategoryIcons.businessIncome,
          'color_hex': CategoryColors.blue,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Investments',
          'type': CategoryType.income.value,
          'icon': CategoryIcons.investment,
          'color_hex': CategoryColors.indigo,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Freelancing',
          'type': CategoryType.income.value,
          'icon': CategoryIcons.freelance,
          'color_hex': CategoryColors.purple,
          'is_default': true,
          'is_active': true,
        },
        {
          'profile_id': profileId,
          'name': 'Gifts',
          'type': CategoryType.income.value,
          'icon': CategoryIcons.gifts,
          'color_hex': CategoryColors.pink,
          'is_default': true,
          'is_active': true,
        },
      ];

      // Insert all categories
      final allCategories = [...expenseCategories, ...incomeCategories];
      final response = await _supabase
          .from(ApiConstants.categoriesTable)
          .insert(allCategories)
          .select();

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      return Success(categories);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
