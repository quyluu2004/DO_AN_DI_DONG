import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;        // Mã: SALE50
  final String title;       // Tên: Giảm 50% áo thun
  final String discountType; // 'percent' hoặc 'fixed'
  final double discountValue; // Giá trị: 10 (10%) hoặc 50000 (50k)
  final double? maxDiscount;  // Tối đa giảm bao nhiêu (cho loại percent)
  final double minOrderValue; // Đơn tối thiểu
  final List<String> targetCategories; // Danh sách category áp dụng (Rỗng = All)
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final bool isFlashSale;
  final DateTime? endTime;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minOrderValue,
    required this.targetCategories,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    this.isFlashSale = false,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'title': title,
      'discountType': discountType,
      'discountValue': discountValue,
      'maxDiscount': maxDiscount,
      'minOrderValue': minOrderValue,
      'targetCategories': targetCategories,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isFlashSale': isFlashSale,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory CouponModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      discountType: map['discountType'] ?? 'fixed',
      discountValue: (map['discountValue'] ?? 0).toDouble(),
      maxDiscount: map['maxDiscount'] != null ? (map['maxDiscount']).toDouble() : null,
      minOrderValue: (map['minOrderValue'] ?? 0).toDouble(),
      targetCategories: List<String>.from(map['targetCategories'] ?? []),
      isActive: map['isActive'] ?? true,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isFlashSale: map['isFlashSale'] ?? false,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
    );
  }
}