class OrderItemModel {
  OrderItemModel({
    required this.productId,
    required this.title,
    required this.image,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String title;
  final String? image;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      image: json['image']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ShippingAddressModel {
  ShippingAddressModel({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  String get formatted => '$street, $city, $state, $postalCode, $country';

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.taxFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.transactionId,
    this.shippingAddress,
  });

  final String id;
  final List<OrderItemModel> items;
  final double subtotal;
  final double shippingFee;
  final double taxFee;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final DateTime? createdAt;
  final String? transactionId;
  final ShippingAddressModel? shippingAddress;

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
      taxFee: (json['taxFee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      orderStatus: json['orderStatus']?.toString() ?? 'placed',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      transactionId: json['transactionId']?.toString(),
      shippingAddress: json['shippingAddress'] is Map<String, dynamic>
          ? ShippingAddressModel.fromJson(
              json['shippingAddress'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
