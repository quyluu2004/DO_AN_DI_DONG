import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String gender; // 'male' | 'female' | 'other'
  final DateTime? birthday;
  final String avatarUrl;
  final String role;
  final bool isVerified;
  final String? fcmToken;
  final List<String> favoriteProductIds;

  final int points;
  final double totalSpent;
  final String tier; // member, silver, gold, diamond
  final DateTime? lastCheckInDate;
  final int checkInStreak;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.gender,
    required this.birthday,
    required this.avatarUrl,
    this.role = 'buyer',
    this.isVerified = false,
    this.fcmToken,
    this.favoriteProductIds = const [],
    this.points = 0,
    this.totalSpent = 0.0,
    this.tier = 'member',
    this.lastCheckInDate,
    this.checkInStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'avatarUrl': avatarUrl,
      'role': role,
      'isVerified': isVerified,
      'fcmToken': fcmToken,
      'favoriteProductIds': favoriteProductIds,
      'points': points,
      'totalSpent': totalSpent,
      'tier': tier,
      'lastCheckInDate': lastCheckInDate != null ? Timestamp.fromDate(lastCheckInDate!) : null,
      'checkInStreak': checkInStreak,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      gender: data['gender'] as String? ?? 'other',
      birthday: (data['birthday'] as Timestamp?)?.toDate(),
      avatarUrl: data['avatarUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'buyer',
      isVerified: data['isVerified'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      favoriteProductIds: List<String>.from(data['favoriteProductIds'] as List<dynamic>? ?? []),
      points: data['points'] as int? ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      tier: data['tier'] as String? ?? 'member',
      lastCheckInDate: (data['lastCheckInDate'] as Timestamp?)?.toDate(),
      checkInStreak: data['checkInStreak'] as int? ?? 0,
    );
  }
}


