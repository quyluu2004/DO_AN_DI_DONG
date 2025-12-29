import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPost {
  final String id;
  final String authorName;
  final String authorId; // [NEW] Link to user
  final String authorAvatarUrl;
  final String imageUrl;
  final String description;
  final List<String> likedBy; // [UPDATED] List of user IDs who liked
  final int commentCount; // [NEW]
  final List<String> linkedProductIds;
  final DateTime timestamp;

  FeedPost({
    required this.id,
    required this.authorName,
    this.authorId = '',
    required this.authorAvatarUrl,
    required this.imageUrl,
    required this.description,
    this.likedBy = const [], // Default empty
    this.commentCount = 0,
    required this.linkedProductIds,
    required this.timestamp,
  });

  int get likeCount => likedBy.length;

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'authorId': authorId,
      'authorAvatarUrl': authorAvatarUrl,
      'imageUrl': imageUrl,
      'description': description,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'linkedProductIds': linkedProductIds,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FeedPost.fromMap(Map<String, dynamic> map, String id) {
    return FeedPost(
      id: id,
      authorName: map['authorName'] ?? '',
      authorId: map['authorId'] ?? '',
      authorAvatarUrl: map['authorAvatarUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      likedBy: List<String>.from(map['likedBy'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      linkedProductIds: List<String>.from(map['linkedProductIds'] ?? []),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
