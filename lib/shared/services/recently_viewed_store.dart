import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

class RecentlyViewedItem {
  const RecentlyViewedItem({
    required this.title,
    required this.slug,
    required this.imageUrl,
    required this.viewedAt,
  });

  final String title;
  final String slug;
  final String imageUrl;
  final DateTime viewedAt;

  factory RecentlyViewedItem.fromProduct(ProductModel product) {
    return RecentlyViewedItem(
      title: product.title,
      slug: product.slug,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      viewedAt: DateTime.now(),
    );
  }

  factory RecentlyViewedItem.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedItem(
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      viewedAt:
          DateTime.tryParse(json['viewedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'imageUrl': imageUrl,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
}

class RecentlyViewedStore {
  RecentlyViewedStore._();

  static const _prefix = 'recentlyViewed';
  static const _maxItems = 5;

  static String _keyFor(String userKey) {
    final safeUserKey = userKey.trim().isEmpty ? 'guest' : userKey.trim();
    return '$_prefix:$safeUserKey';
  }

  static Future<List<RecentlyViewedItem>> load(String userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_keyFor(userKey)) ?? const [];
    final items = rawItems
        .map((value) {
          try {
            return RecentlyViewedItem.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentlyViewedItem>()
        .toList();

    items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return items.take(_maxItems).toList();
  }

  static Future<void> recordView({
    required String userKey,
    required ProductModel product,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load(userKey);
    final updated = <RecentlyViewedItem>[
      RecentlyViewedItem.fromProduct(product),
      ...existing.where((item) => item.slug != product.slug),
    ].take(_maxItems).toList();

    await prefs.setStringList(
      _keyFor(userKey),
      updated.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
