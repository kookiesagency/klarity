import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/category_type.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';

/// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Category state
class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get expense categories
  List<CategoryModel> get expenseCategories {
    return categories
        .where((c) => c.type == CategoryType.expense && c.isActive)
        .toList();
  }

  /// Get income categories
  List<CategoryModel> get incomeCategories {
    return categories
        .where((c) => c.type == CategoryType.income && c.isActive)
        .toList();
  }

  CategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Category notifier
class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repository;
  final Ref _ref;

  CategoryNotifier(this._repository, this._ref) : super(const CategoryState()) {
    // Listen to profile changes
    _ref.listen<ProfileModel?>(
      activeProfileProvider,
      (previous, next) {
        if (next != null) {
          // Delay state modification to avoid build-time updates
          Future.microtask(() {
            loadCategories(next.id);
          });
        }
      },
    );

    // Try initial load
    _initialize();
  }

  /// Initialize categories
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      final activeProfile = _ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      await loadCategories(activeProfile.id);
    });
  }

  /// Load all categories for profile
  Future<void> loadCategories(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getCategories(profileId);

    result.fold(
      onSuccess: (categories) async {
        state = state.copyWith(
          categories: categories,
          isLoading: false,
          error: null,
        );

        // If no categories exist, create defaults
        if (categories.isEmpty) {
          await _createDefaultCategories(profileId);
        }
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Load categories by type
  Future<void> loadCategoriesByType({
    required String profileId,
    required CategoryType type,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getCategoriesByType(
      profileId: profileId,
      type: type,
    );

    result.fold(
      onSuccess: (categories) {
        state = state.copyWith(
          categories: categories,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Create default categories
  Future<void> _createDefaultCategories(String profileId) async {
    final result = await _repository.createDefaultCategories(profileId);

    result.fold(
      onSuccess: (categories) {
        state = state.copyWith(
          categories: categories,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );
  }

  /// Create new category
  Future<Result<CategoryModel>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
    required String colorHex,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createCategory(
      profileId: activeProfile.id,
      name: name,
      type: type,
      icon: icon,
      colorHex: colorHex,
      isDefault: false,
    );

    result.fold(
      onSuccess: (category) {
        state = state.copyWith(
          categories: [...state.categories, category],
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Update category
  Future<Result<CategoryModel>> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? colorHex,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      colorHex: colorHex,
    );

    result.fold(
      onSuccess: (updatedCategory) {
        final updatedCategories = state.categories.map((c) {
          return c.id == categoryId ? updatedCategory : c;
        }).toList();

        state = state.copyWith(
          categories: updatedCategories,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Delete category (soft delete)
  Future<Result<void>> deleteCategory(String categoryId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteCategory(categoryId);

    result.fold(
      onSuccess: (_) {
        final updatedCategories =
            state.categories.where((c) => c.id != categoryId).toList();

        state = state.copyWith(
          categories: updatedCategories,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Refresh categories
  Future<void> refresh() async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await loadCategories(activeProfile.id);
    }
  }
}

/// Category provider
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository, ref);
});

/// Categories list provider (all active categories)
final categoriesListProvider = Provider<List<CategoryModel>>((ref) {
  final categoryState = ref.watch(categoryProvider);
  return categoryState.categories;
});

/// Expense categories provider
final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoryState = ref.watch(categoryProvider);
  return categoryState.expenseCategories;
});

/// Income categories provider
final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoryState = ref.watch(categoryProvider);
  return categoryState.incomeCategories;
});
