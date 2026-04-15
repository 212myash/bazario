class ReviewModel {
  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    this.userAvatar,
    this.createdAt,
  });

  final String id;
  final String userName;
  final int rating;
  final String comment;
  final String? userAvatar;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ReviewModel(
      id: json['_id']?.toString() ?? '',
      userName: user['name']?.toString() ?? 'User',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      userAvatar: user['avatarUrl']?.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
