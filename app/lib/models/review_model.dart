
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatarUrl; // Renamed to match usage in service
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userAvatarUrl: map['userAvatarUrl'], // Updated key
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
