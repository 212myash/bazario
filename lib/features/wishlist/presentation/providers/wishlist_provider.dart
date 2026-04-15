import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/product_model.dart';
import '../../data/wishlist_api_service.dart';

class WishlistState {
  const WishlistState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.items = const [],
  });

  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final List<ProductModel> items;

  WishlistState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    List<ProductModel>? items,
    bool clearError = false,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
    );
  }
}

final wishlistApiServiceProvider = Provider<WishlistApiService>((ref) {
  return WishlistApiService(ref.watch(dioProvider));
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    return WishlistNotifier(ref.watch(wishlistApiServiceProvider));
  },
);

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier(this._api) : super(const WishlistState());

  final WishlistApiService _api;

  Future<void> fetchWishlist() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.getWishlist();
      final data = (response['data'] ?? {}) as Map<String, dynamic>;
      final items = (data['products'] as List<dynamic>? ?? [])
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, items: items, clearError: true);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to load wishlist',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load wishlist',
      );
    }
  }

  Future<void> add(String productId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.addToWishlist(productId);
      final data = (response['data'] ?? {}) as Map<String, dynamic>;
      final items = (data['products'] as List<dynamic>? ?? [])
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isSaving: false, items: items, clearError: true);
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> remove(String productId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.removeFromWishlist(productId);
      final data = (response['data'] ?? {}) as Map<String, dynamic>;
      final items = (data['products'] as List<dynamic>? ?? [])
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isSaving: false, items: items, clearError: true);
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }
}
