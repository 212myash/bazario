import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/order_model.dart';
import '../../data/order_api_service.dart';

class OrderState {
  const OrderState({
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.orders = const [],
    this.page = 1,
    this.totalPages = 1,
  });

  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<OrderModel> orders;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  OrderState copyWith({
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<OrderModel>? orders,
    int? page,
    int? totalPages,
    bool clearError = false,
  }) {
    return OrderState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      orders: orders ?? this.orders,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

final orderApiServiceProvider = Provider<OrderApiService>((ref) {
  return OrderApiService(ref.watch(dioProvider));
});

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref.watch(orderApiServiceProvider));
});

final orderDetailsProvider = FutureProvider.family<OrderModel, String>((
  ref,
  orderId,
) async {
  final api = ref.read(orderApiServiceProvider);
  final response = await api.getOrderById(orderId);
  return OrderModel.fromJson((response['data'] ?? {}) as Map<String, dynamic>);
});

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier(this._api) : super(const OrderState());

  final OrderApiService _api;

  Future<void> fetchOrders({bool refresh = false}) async {
    final targetPage = refresh ? 1 : state.page;
    if (refresh) {
      state = state.copyWith(
        isInitialLoading: true,
        clearError: true,
        orders: [],
        page: 1,
        totalPages: 1,
      );
    } else {
      state = state.copyWith(isInitialLoading: true, clearError: true);
    }

    try {
      final response = await _api.getMyOrders(page: targetPage);
      final items = (response['data'] as List<dynamic>? ?? [])
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final pagination =
          ((response['meta'] ?? {}) as Map<String, dynamic>)['pagination']
              as Map<String, dynamic>?;

      state = state.copyWith(
        isInitialLoading: false,
        orders: items,
        page: (pagination?['page'] as num?)?.toInt() ?? 1,
        totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
        clearError: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to load orders',
      );
    } catch (_) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: 'Failed to load orders',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final response = await _api.getMyOrders(page: nextPage);
      final items = (response['data'] as List<dynamic>? ?? [])
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final pagination =
          ((response['meta'] ?? {}) as Map<String, dynamic>)['pagination']
              as Map<String, dynamic>?;

      state = state.copyWith(
        isLoadingMore: false,
        orders: [...state.orders, ...items],
        page: (pagination?['page'] as num?)?.toInt() ?? nextPage,
        totalPages:
            (pagination?['totalPages'] as num?)?.toInt() ?? state.totalPages,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to load more orders',
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more orders',
      );
    }
  }
}
