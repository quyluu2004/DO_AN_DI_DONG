
import 'package:cloud_firestore/cloud_firestore.dart';

enum FitRating {
  small,
  trueToSize,
  large,
}

extension FitRatingExtension on FitRating {
  String get value {
    switch (this) {
      case FitRating.small:
        return 'small';
      case FitRating.trueToSize:
        return 'true_to_size';
      case FitRating.large:
        return 'large';
    }
  }

  static FitRating fromString(String value) {
    switch (value) {
      case 'small':
        return FitRating.small;
      case 'true_to_size':
        return FitRating.trueToSize;
      case 'large':
        return FitRating.large;
      default:
        return FitRating.trueToSize;
    }
  }
}

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final String? color;
  final String? size;
  final int helpfulCount;
  final List<String> images;
  final DateTime createdAt;
  
  // New Fields
  final FitRating fitRating;
  final double? userHeight; // cm
  final double? userWeight; // kg

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    this.color,
    this.size,
    this.helpfulCount = 0,
    this.images = const [],
    required this.createdAt,
    this.fitRating = FitRating.trueToSize,
    this.userHeight,
    this.userWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'color': color,
      'size': size,
      'helpfulCount': helpfulCount,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'fitRating': fitRating.value,
      'userHeight': userHeight,
      'userWeight': userWeight,
    };
  }

  factory Review.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userAvatar: map['userAvatar'],
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      color: map['color'],
      size: map['size'],
      helpfulCount: map['helpfulCount'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      fitRating: FitRatingExtension.fromString(map['fitRating'] ?? 'true_to_size'),
      userHeight: (map['userHeight'] as num?)?.toDouble(),
      userWeight: (map['userWeight'] as num?)?.toDouble(),
    );
  }
}
