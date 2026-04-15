import 'category_model.dart';
import 'review_model.dart';

class ProductModel {
  ProductModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.stock,
    required this.ratingAverage,
    required this.ratingCount,
    required this.images,
    this.reviews = const [],
    this.category,
  });

  final String id;
  final String title;
  final String slug;
  final String description;
  final double price;
  final double? discountedPrice;
  final int stock;
  final double ratingAverage;
  final int ratingCount;
  final List<String> images;
  final List<ReviewModel> reviews;
  final CategoryModel? category;

  double get displayPrice => discountedPrice ?? price;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List<dynamic>? ?? [])
        .map((item) => (item as Map<String, dynamic>)['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    final categoryJson = json['category'] is Map<String, dynamic>
        ? json['category'] as Map<String, dynamic>
        : null;

    return ProductModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      images: imageList,
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      category: categoryJson != null
          ? CategoryModel.fromJson(categoryJson)
          : null,
    );
  }
}
