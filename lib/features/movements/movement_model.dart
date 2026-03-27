class Movement {
  final String? id;
  final String userId;
  final double amount;
  final String type; // 'ingreso' or 'egreso'
  final String category;
  final String emoji;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  Movement({
    this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.emoji,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      category: json['category'],
      emoji: json['emoji'],
      description: json['description'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'emoji': emoji,
      'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
