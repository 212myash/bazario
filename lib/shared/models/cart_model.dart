import 'product_model.dart';

class CartItemModel {
  CartItemModel({
    required this.product,
    required this.quantity,
    required this.priceSnapshot,
  });

  final ProductModel? product;
  final int quantity;
  final double priceSnapshot;

  double get lineTotal => priceSnapshot * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : null;

    return CartItemModel(
      product: productJson == null ? null : ProductModel.fromJson(productJson),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      priceSnapshot: (json['priceSnapshot'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CartModel {
  CartModel({required this.items});

  final List<CartItemModel> items;

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
