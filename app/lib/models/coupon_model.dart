import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final double discountAmount; 
  final double minOrderValue;
  final bool isActive;
  final DateTime createdAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.minOrderValue,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'discountAmount': discountAmount,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CouponModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: map['code'] ?? '',
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      minOrderValue: (map['minOrderValue'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
