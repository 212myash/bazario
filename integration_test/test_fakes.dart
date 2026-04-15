import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:bazario/features/auth/data/auth_api_service.dart';
import 'package:bazario/features/cart/data/cart_api_service.dart';
import 'package:bazario/features/order/data/checkout_api_service.dart';
import 'package:bazario/features/order/data/order_api_service.dart';
import 'package:bazario/features/order/data/payment_gateway.dart';
import 'package:bazario/features/product/data/product_api_service.dart';
import 'package:bazario/features/profile/data/profile_api_service.dart';
import 'package:bazario/features/wishlist/data/wishlist_api_service.dart';
import 'package:bazario/core/utils/token_storage.dart';
import 'package:bazario/shared/models/cart_model.dart';
import 'package:bazario/shared/models/product_model.dart';
import 'package:bazario/shared/models/user_model.dart';

Map<String, dynamic> _userJson({
  required String name,
  String email = 'john@example.com',
  String role = 'user',
  String phone = '9999999999',
  List<AddressModel> addresses = const [],
}) {
  return {
    '_id': 'user_1',
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'addresses': addresses
        .map(
          (address) => {
            '_id': address.id,
            'fullName': address.fullName,
            'phone': address.phone,
            'street': address.street,
            'city': address.city,
            'state': address.state,
            'postalCode': address.postalCode,
            'country': address.country,
            'label': address.label,
            'isDefault': address.isDefault,
          },
        )
        .toList(),
  };
}

Map<String, dynamic> productJson({
  required String id,
  required String slug,
  required String title,
  double price = 999,
  String categoryId = 'cat_1',
  String categoryName = 'Electronics',
  List<Map<String, dynamic>>? reviews,
}) {
  return {
    '_id': id,
    'slug': slug,
    'title': title,
    'description': 'Test description for $title',
    'price': price,
    'discountedPrice': price - 100,
    'stock': 10,
    'ratingAverage': 4.5,
    'ratingCount': reviews?.length ?? 1,
    'images': [
      {'url': 'https://example.com/$id.jpg'},
    ],
    'category': {
      '_id': categoryId,
      'name': categoryName,
      'slug': categoryName.toLowerCase(),
    },
    'reviews':
        reviews ??
        [
          {
            '_id': 'review_1',
            'user': {'name': 'Jane', 'avatarUrl': ''},
            'rating': 5,
            'comment': 'Great product',
            'createdAt': DateTime(2026, 4, 15).toIso8601String(),
          },
        ],
  };
}

Map<String, dynamic> orderJson({
  required String id,
  required String status,
  required int page,
  required int totalPages,
}) {
  return {
    '_id': id,
    'items': [
      {
        'product': 'prod_1',
        'title': 'Demo Product',
        'image': 'https://example.com/prod_1.jpg',
        'quantity': 1,
        'unitPrice': 499,
        'lineTotal': 499,
      },
    ],
    'subtotal': 499,
    'shippingFee': 0,
    'taxFee': 0,
    'totalAmount': 499,
    'paymentMethod': 'razorpay',
    'paymentStatus': status == 'placed' ? 'pending' : 'paid',
    'orderStatus': status,
    'createdAt': DateTime(2026, 4, 15).toIso8601String(),
    'shippingAddress': {
      'fullName': 'John User',
      'phone': '9999999999',
      'street': '123 Main St',
      'city': 'Mumbai',
      'state': 'MH',
      'postalCode': '400001',
      'country': 'India',
    },
    'meta': {
      'pagination': {'page': page, 'totalPages': totalPages},
    },
  };
}

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage() : super(const FlutterSecureStorage());

  String? _token;

  @override
  Future<void> saveAccessToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<void> clear() async {
    _token = null;
  }
}

class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService({this.failLogin = false}) : super(Dio());

  final bool failLogin;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (failLogin) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {'message': 'Invalid credentials'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return {
      'success': true,
      'data': {
        'accessToken': 'token_123',
        'refreshToken': 'refresh_123',
        'user': _userJson(name: 'John User', email: email),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return {
      'success': true,
      'data': {
        'accessToken': 'token_123',
        'user': _userJson(name: name, email: email),
      },
    };
  }

  @override
  Future<void> logout() async {}
}

class FakeProductApiService extends ProductApiService {
  FakeProductApiService() : super(Dio());

  @override
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 12,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    final page1 = [
      productJson(
        id: 'prod_1',
        slug: 'demo-product-1',
        title: 'Demo Product 1',
      ),
      productJson(
        id: 'prod_2',
        slug: 'demo-product-2',
        title: 'Demo Product 2',
      ),
    ];
    final page2 = [
      productJson(
        id: 'prod_3',
        slug: 'demo-product-3',
        title: 'Demo Product 3',
      ),
    ];
    final items = page == 1 ? page1 : page2;
    return {
      'success': true,
      'data': items,
      'meta': {
        'pagination': {'page': page, 'totalPages': 2},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getProductDetails(String slug) async {
    return {
      'success': true,
      'data': productJson(id: 'prod_1', slug: slug, title: 'Demo Product 1'),
    };
  }

  @override
  Future<Map<String, dynamic>> getCategories() async {
    return {
      'success': true,
      'data': [
        {'_id': 'cat_1', 'name': 'Electronics', 'slug': 'electronics'},
        {'_id': 'cat_2', 'name': 'Fashion', 'slug': 'fashion'},
      ],
    };
  }
}

class FakeCartApiService extends CartApiService {
  FakeCartApiService() : super(Dio());

  final List<CartItemModel> _items = [
    CartItemModel(
      product: ProductModel.fromJson(
        productJson(
          id: 'prod_1',
          slug: 'demo-product-1',
          title: 'Demo Product 1',
        ),
      ),
      quantity: 1,
      priceSnapshot: 499,
    ),
  ];

  Map<String, dynamic> _cartResponse() {
    return {
      'success': true,
      'data': {
        'items': _items
            .map(
              (item) => {
                'product': {
                  ...productJson(
                    id: item.product!.id,
                    slug: item.product!.slug,
                    title: item.product!.title,
                  ),
                },
                'quantity': item.quantity,
                'priceSnapshot': item.priceSnapshot,
                'titleSnapshot': item.product!.title,
                'imageSnapshot': item.product!.images.first,
              },
            )
            .toList(),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getCart() async => _cartResponse();

  @override
  Future<Map<String, dynamic>> addItem(
    String productId, {
    int quantity = 1,
  }) async {
    final product = ProductModel.fromJson(
      productJson(
        id: productId,
        slug: 'demo-$productId',
        title: 'Demo $productId',
      ),
    );
    final existingIndex = _items.indexWhere(
      (item) => item.product?.id == productId,
    );
    if (existingIndex >= 0) {
      _items[existingIndex] = CartItemModel(
        product: _items[existingIndex].product,
        quantity: _items[existingIndex].quantity + quantity,
        priceSnapshot: _items[existingIndex].priceSnapshot,
      );
    } else {
      _items.add(
        CartItemModel(product: product, quantity: quantity, priceSnapshot: 499),
      );
    }
    return _cartResponse();
  }

  @override
  Future<Map<String, dynamic>> updateItem(
    String productId,
    int quantity,
  ) async {
    final index = _items.indexWhere((item) => item.product?.id == productId);
    if (index >= 0) {
      _items[index] = CartItemModel(
        product: _items[index].product,
        quantity: quantity,
        priceSnapshot: _items[index].priceSnapshot,
      );
    }
    return _cartResponse();
  }

  @override
  Future<Map<String, dynamic>> removeItem(String productId) async {
    _items.removeWhere((item) => item.product?.id == productId);
    return _cartResponse();
  }
}

class FakeProfileApiService extends ProfileApiService {
  FakeProfileApiService() : super(Dio());

  final List<AddressModel> _addresses = [
    AddressModel(
      id: 'addr_1',
      fullName: 'John User',
      phone: '9999999999',
      street: '123 Main St',
      city: 'Mumbai',
      state: 'MH',
      postalCode: '400001',
      country: 'India',
      isDefault: true,
    ),
  ];

  @override
  Future<Map<String, dynamic>> getMyProfile() async {
    return {
      'success': true,
      'data': _userJson(
        name: 'John User',
        phone: '9999999999',
        addresses: _addresses,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    return {
      'success': true,
      'data': _userJson(
        name: name,
        phone: phone ?? '9999999999',
        addresses: _addresses,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> payload) async {
    _addresses.add(
      AddressModel.fromJson({
        ...payload,
        '_id': 'addr_${_addresses.length + 1}',
      }),
    );
    return {
      'success': true,
      'data': _addresses
          .map(
            (address) => {
              '_id': address.id,
              'fullName': address.fullName,
              'phone': address.phone,
              'street': address.street,
              'city': address.city,
              'state': address.state,
              'postalCode': address.postalCode,
              'country': address.country,
              'label': address.label,
              'isDefault': address.isDefault,
            },
          )
          .toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  ) async {
    final index = _addresses.indexWhere((address) => address.id == addressId);
    if (index >= 0) {
      _addresses[index] = AddressModel.fromJson({
        '_id': addressId,
        ...payload,
        'isDefault': _addresses[index].isDefault,
      });
    }
    return {
      'success': true,
      'data': _addresses
          .map(
            (address) => {
              '_id': address.id,
              'fullName': address.fullName,
              'phone': address.phone,
              'street': address.street,
              'city': address.city,
              'state': address.state,
              'postalCode': address.postalCode,
              'country': address.country,
              'label': address.label,
              'isDefault': address.isDefault,
            },
          )
          .toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    _addresses.removeWhere((address) => address.id == addressId);
    return {
      'success': true,
      'data': _addresses
          .map(
            (address) => {
              '_id': address.id,
              'fullName': address.fullName,
              'phone': address.phone,
              'street': address.street,
              'city': address.city,
              'state': address.state,
              'postalCode': address.postalCode,
              'country': address.country,
              'label': address.label,
              'isDefault': address.isDefault,
            },
          )
          .toList(),
    };
  }
}

class FakeWishlistApiService extends WishlistApiService {
  FakeWishlistApiService() : super(Dio());

  final List<ProductModel> _items = [
    ProductModel.fromJson(
      productJson(
        id: 'prod_2',
        slug: 'demo-product-2',
        title: 'Demo Product 2',
      ),
    ),
  ];

  Map<String, dynamic> _response() => {
    'success': true,
    'data': {
      'products': _items
          .map(
            (product) => productJson(
              id: product.id,
              slug: product.slug,
              title: product.title,
            ),
          )
          .toList(),
    },
  };

  @override
  Future<Map<String, dynamic>> getWishlist() async => _response();

  @override
  Future<Map<String, dynamic>> addToWishlist(String productId) async {
    final product = ProductModel.fromJson(
      productJson(
        id: productId,
        slug: 'demo-$productId',
        title: 'Demo $productId',
      ),
    );
    if (_items.every((item) => item.id != productId)) {
      _items.add(product);
    }
    return _response();
  }

  @override
  Future<Map<String, dynamic>> removeFromWishlist(String productId) async {
    _items.removeWhere((item) => item.id == productId);
    return _response();
  }
}

class FakeOrderApiService extends OrderApiService {
  FakeOrderApiService() : super(Dio());

  @override
  Future<Map<String, dynamic>> getMyOrders({
    required int page,
    int limit = 10,
  }) async {
    final data = page == 1
        ? [
            orderJson(id: 'order_1', status: 'placed', page: 1, totalPages: 2),
            orderJson(
              id: 'order_a',
              status: 'processing',
              page: 1,
              totalPages: 2,
            ),
            orderJson(id: 'order_b', status: 'shipped', page: 1, totalPages: 2),
            orderJson(
              id: 'order_c',
              status: 'delivered',
              page: 1,
              totalPages: 2,
            ),
            orderJson(
              id: 'order_d',
              status: 'cancelled',
              page: 1,
              totalPages: 2,
            ),
          ]
        : [
            orderJson(
              id: 'order_2',
              status: 'delivered',
              page: 2,
              totalPages: 2,
            ),
          ];
    return {
      'success': true,
      'data': data,
      'meta': {
        'pagination': {'page': page, 'totalPages': 2},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    return {
      'success': true,
      'data': orderJson(id: orderId, status: 'shipped', page: 1, totalPages: 1),
    };
  }
}

class FakeCheckoutApiService extends CheckoutApiService {
  FakeCheckoutApiService({this.failVerification = false}) : super(Dio());

  final bool failVerification;
  String? lastOrderId;

  @override
  Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    lastOrderId = 'order_checkout_1';
    return {
      'success': true,
      'data': orderJson(
        id: lastOrderId!,
        status: 'placed',
        page: 1,
        totalPages: 1,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> createRazorpayOrder(String orderId) async {
    return {
      'success': true,
      'data': {
        'razorpayOrder': {'id': 'rzp_order_1', 'amount': 49900},
        'keyId': 'rzp_test_key',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> verifyRazorpay({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (failVerification) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/payments/razorpay/verify'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/payments/razorpay/verify'),
          statusCode: 400,
          data: {'message': 'Invalid payment signature'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return {
      'success': true,
      'data': {'verified': true},
    };
  }
}

class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({this.autoSuccess = true, this.autoError = false});

  final bool autoSuccess;
  final bool autoError;

  late void Function(PaymentSuccessPayload response) _onSuccess;
  late void Function(PaymentFailurePayload response) _onError;
  late void Function(ExternalWalletPayload response) _onExternalWallet;

  Map<String, dynamic>? lastOptions;

  @override
  void open({
    required Map<String, dynamic> options,
    required void Function(PaymentSuccessPayload response) onSuccess,
    required void Function(PaymentFailurePayload response) onError,
    required void Function(ExternalWalletPayload response) onExternalWallet,
  }) {
    lastOptions = options;
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    scheduleMicrotask(() {
      if (autoError) {
        _onError(
          const PaymentFailurePayload(code: 1, message: 'Payment failed'),
        );
      } else if (autoSuccess) {
        _onSuccess(
          const PaymentSuccessPayload(
            paymentId: 'pay_1',
            orderId: 'rzp_order_1',
            signature: 'signature_1',
          ),
        );
      } else {
        _onExternalWallet(const ExternalWalletPayload(walletName: 'Wallet'));
      }
    });
  }

  @override
  void dispose() {}
}
