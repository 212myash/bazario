class CategoryModel {
  CategoryModel({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}
