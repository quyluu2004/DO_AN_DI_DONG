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
    );
  }
}


