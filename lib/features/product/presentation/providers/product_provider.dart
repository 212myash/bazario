import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../data/product_api_service.dart';

class ProductState {
  const ProductState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.products = const [],
    this.categories = const [],
    this.search = '',
    this.selectedCategory = '',
    this.page = 1,
    this.totalPages = 1,
    this.minPrice,
    this.maxPrice,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String search;
  final String selectedCategory;
  final int page;
  final int totalPages;
  final double? minPrice;
  final double? maxPrice;

  bool get hasMore => page < totalPages;

  ProductState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? search,
    String? selectedCategory,
    int? page,
    int? totalPages,
    double? minPrice,
    double? maxPrice,
    bool clearError = false,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      products: products ?? this.products,
      categories: categories ?? this.categories,
      search: search ?? this.search,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

final productApiServiceProvider = Provider<ProductApiService>((ref) {
  return ProductApiService(ref.watch(dioProvider));
});

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((
  ref,
) {
  return ProductNotifier(ref.watch(productApiServiceProvider))..bootstrap();
});

class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier(this._api) : super(const ProductState());

  final ProductApiService _api;

  Future<void> bootstrap() async {
    await Future.wait([fetchProducts(), fetchCategories()]);
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    final page = refresh ? 1 : state.page;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      products: refresh ? [] : state.products,
      page: refresh ? 1 : state.page,
      totalPages: refresh ? 1 : state.totalPages,
    );

    try {
      final response = await _api.getProducts(
        page: page,
        search: state.search,
        category: state.selectedCategory.isEmpty
            ? null
            : state.selectedCategory,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );
      final items = (response['data'] as List<dynamic>? ?? [])
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final pagination =
          ((response['meta'] ?? {}) as Map<String, dynamic>)['pagination']
              as Map<String, dynamic>?;

      state = state.copyWith(
        isLoading: false,
        products: items,
        page: (pagination?['page'] as num?)?.toInt() ?? 1,
        totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
        clearError: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to load products',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load products',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final response = await _api.getProducts(
        page: nextPage,
        search: state.search,
        category: state.selectedCategory.isEmpty
            ? null
            : state.selectedCategory,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );

      final items = (response['data'] as List<dynamic>? ?? [])
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final pagination =
          ((response['meta'] ?? {}) as Map<String, dynamic>)['pagination']
              as Map<String, dynamic>?;

      state = state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...items],
        page: (pagination?['page'] as num?)?.toInt() ?? nextPage,
        totalPages:
            (pagination?['totalPages'] as num?)?.toInt() ?? state.totalPages,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _api.getCategories();
      final items = (response['data'] as List<dynamic>? ?? [])
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(categories: items);
    } catch (_) {
      // Non-blocking: products still work without categories.
    }
  }

  Future<void> updateSearch(String value) async {
    state = state.copyWith(search: value);
    await fetchProducts(refresh: true);
  }

  Future<void> updateCategory(String value) async {
    state = state.copyWith(selectedCategory: value);
    await fetchProducts(refresh: true);
  }
}

final productDetailsProvider = FutureProvider.family<ProductModel, String>((
  ref,
  slug,
) async {
  final response = await ref
      .read(productApiServiceProvider)
      .getProductDetails(slug);
  return ProductModel.fromJson(
    (response['data'] ?? {}) as Map<String, dynamic>,
  );
});
