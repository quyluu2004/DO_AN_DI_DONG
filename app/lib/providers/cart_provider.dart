
import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/coupon_service.dart'; // [NEW]
import '../models/coupon_model.dart'; // [NEW]

class CartProvider extends ChangeNotifier {
  Cart _cart = Cart(userId: '');

  Cart get cart => _cart;

  // Return total count of ALL items (for badge)
  int get itemCount => _cart.items.fold(0, (sum, item) => sum + item.quantity);
  
  // Return count of SELECTED items (for checkout button)
  int get selectedItemCount => _cart.items.where((i) => i.isSelected).length;

  // Return total price of SELECTED items
  // Return total price of SELECTED items (Scanning implementation)
  double get subtotal => _cart.items
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.totalPrice);
  
  CouponModel? _appliedCoupon;
  CouponModel? get appliedCoupon => _appliedCoupon;
  String? _couponError;
  String? get couponError => _couponError;

  double get discountAmount {
    if (_appliedCoupon == null) return 0;
    return _appliedCoupon!.discountAmount;
  }

  double get totalAmount {
    double total = subtotal - discountAmount;
    return total > 0 ? total : 0;
  }
  
  Future<void> applyCoupon(String code) async {
    _couponError = null;
    notifyListeners();
    
    try {
      final coupon = await CouponService.instance.validateCoupon(code, subtotal);
      if (coupon != null) {
        _appliedCoupon = coupon;
        notifyListeners();
      }
    } catch (e) {
      _appliedCoupon = null;
      _couponError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponError = null;
    notifyListeners();
  }
  
  bool get isAllSelected => _cart.items.isNotEmpty && _cart.items.every((item) => item.isSelected);

  void addToCart(Product product, {String? size, String? color, int quantity = 1}) {
    final existingIndex = _cart.items.indexWhere((item) =>
        item.productId == product.id && item.size == size && item.color == color);

    if (existingIndex >= 0) {
      _cart.items[existingIndex].quantity += quantity;
    } else {
      _cart.items.add(CartItem(
        productId: product.id,
        productName: product.name,
        imageUrl: product.images.isNotEmpty ? product.images.first : '', 
        price: product.price.toDouble(),
        quantity: quantity,
        size: size,
        color: color,
        tryOnImageUrl: product.tryOnImageUrl, // [NEW]
        subCategory: product.subCategory,     // [NEW]
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId, String? size, String? color) {
    _cart.items.removeWhere((item) =>
        item.productId == productId && item.size == size && item.color == color);
    notifyListeners();
  }

  void updateQuantity(String productId, String? size, String? color, int quantity) {
    final index = _cart.items.indexWhere((item) =>
        item.productId == productId && item.size == size && item.color == color);

    if (index >= 0) {
      if (quantity <= 0) {
        removeFromCart(productId, size, color);
      } else {
        _cart.items[index].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _cart = Cart(userId: _cart.userId);
    notifyListeners();
  }
  


  void toggleSelection(String productId, String? size, String? color) {
    final index = _cart.items.indexWhere((item) =>
        item.productId == productId && item.size == size && item.color == color);
    
    if (index >= 0) {
      _cart.items[index].isSelected = !_cart.items[index].isSelected;
      notifyListeners();
    }
  }

  void toggleAll(bool? value) {
    if (value == null) return;
    for (var item in _cart.items) {
      item.isSelected = value;
    }
    notifyListeners();
  }
  
  // TODO: Sync cart to Firestore if user is logged in
}
