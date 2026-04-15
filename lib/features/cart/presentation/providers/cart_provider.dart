import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/cart_model.dart';
import '../../data/cart_api_service.dart';

class CartState {
  const CartState({this.isLoading = false, this.cart, this.errorMessage});

  final bool isLoading;
  final CartModel? cart;
  final String? errorMessage;

  CartState copyWith({
    bool? isLoading,
    CartModel? cart,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      cart: cart ?? this.cart,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final cartApiServiceProvider = Provider<CartApiService>((ref) {
  return CartApiService(ref.watch(dioProvider));
});

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(cartApiServiceProvider));
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._api) : super(const CartState());

  final CartApiService _api;

  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.getCart();
      final cart = CartModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, cart: cart, clearError: true);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to load cart',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load cart',
      );
    }
  }

  Future<void> addItem(String productId, {int quantity = 1}) async {
    try {
      final response = await _api.addItem(productId, quantity: quantity);
      final cart = CartModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(cart: cart, clearError: true);
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to add item',
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to add item');
    }
  }

  Future<void> updateItem(String productId, int quantity) async {
    try {
      final response = await _api.updateItem(productId, quantity);
      final cart = CartModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(cart: cart, clearError: true);
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to update item',
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to update item');
    }
  }

  Future<void> removeItem(String productId) async {
    try {
      final response = await _api.removeItem(productId);
      final cart = CartModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(cart: cart, clearError: true);
    } on DioException catch (error) {
      state = state.copyWith(
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to remove item',
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to remove item');
    }
  }
}
