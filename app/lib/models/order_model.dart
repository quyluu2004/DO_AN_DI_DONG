import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';
import 'address_model.dart';

enum OrderStatus {
  pending('Chờ xác nhận'),
  shipping('Đang giao'),
  delivered('Đã giao'),
  cancelled('Đã hủy');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String? status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final Address shippingAddress;
  final OrderStatus status;
  final String paymentMethod;
  final DateTime createdAt;
  final double discountAmount;
  final String? couponCode;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.discountAmount = 0,
    this.couponCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress.toMap(),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'discountAmount': discountAmount,
      'couponCode': couponCode,
    };
  }

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: map['userId'] ?? '',
      items: List<CartItem>.from(
        (map['items'] as List<dynamic>).map<CartItem>(
          (x) => CartItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      shippingAddress: Address.fromMap(map['shippingAddress'] as Map<String, dynamic>),
      status: OrderStatus.fromString(map['status']),
      paymentMethod: map['paymentMethod'] ?? 'COD',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      couponCode: map['couponCode'],
    );
  }
}
