
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String? variantId;
  final String productName;
  final String imageUrl;
  final double price;
  final String? size;
  final String? color;
  final String? tryOnImageUrl; // [NEW]
  final String? subCategory;   // [NEW]
  int quantity;
  bool isSelected;

  CartItem({
    required this.productId,
    this.variantId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    this.size,
    this.color,
    this.tryOnImageUrl,
    this.subCategory,
    this.quantity = 1,
    this.isSelected = true,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'size': size,
      'color': color,
      'tryOnImageUrl': tryOnImageUrl,
      'subCategory': subCategory,
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      variantId: map['variantId'],
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      size: map['size'],
      color: map['color'],
      tryOnImageUrl: map['tryOnImageUrl'],
      subCategory: map['subCategory'],
      quantity: map['quantity'] ?? 1,
      isSelected: map['isSelected'] ?? true, // Default to selected
    );
  }
}

class Cart {
  final String userId;
  final List<CartItem> items;
  final double totalAmount;

  Cart({
    required this.userId,
    List<CartItem>? items,
    this.totalAmount = 0,
  }) : items = items ?? [];

  Cart copyWith({
    String? userId,
    List<CartItem>? items,
    double? totalAmount,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
