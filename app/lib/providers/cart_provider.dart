import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/coupon_service.dart';
import '../models/coupon_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class CartProvider extends ChangeNotifier {
  Cart _cart = Cart(userId: '');
  
  // Getter cơ bản
  Cart get cart => _cart;
  int get itemCount => _cart.items.fold(0, (sum, item) => sum + item.quantity);
  int get selectedItemCount => _cart.items.where((i) => i.isSelected).length;

  // Tổng tiền hàng tạm tính (chưa giảm)
  double get subtotal => _cart.items
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  // --- LOGIC COUPON MỚI ---
  CouponModel? _appliedCoupon;
  CouponModel? get appliedCoupon => _appliedCoupon;
  String? _couponError;
  String? get couponError => _couponError;

  // Thêm biến quản lý phí ship
  double _shippingFee = 12000; // Phí ship mặc định (hoặc lấy từ API)
  double get shippingFee => _shippingFee;

  // [MỚI] Tính tiền giảm phí vận chuyển (Free Ship)
  double get shippingDiscountAmount {
    if (_appliedCoupon == null) return 0;
    if (_appliedCoupon!.type != CouponType.freeShip) return 0;

    double originalShippingFee = _shippingFee; 

    // Nếu coupon là Free Ship, giảm tối đa maxShippingDiscount
    if (_appliedCoupon!.maxShippingDiscount > 0) {
      return originalShippingFee <= _appliedCoupon!.maxShippingDiscount 
          ? originalShippingFee 
          : _appliedCoupon!.maxShippingDiscount;
    }
    
    return originalShippingFee; // Nếu không set max, free 100%
  }

  // [CẬP NHẬT] Tính số tiền được giảm giá ĐƠN HÀNG
  double get discountAmount {
    if (_appliedCoupon == null) return 0;
    if (_appliedCoupon!.type == CouponType.freeShip) return 0; // Nếu là mã FreeShip thì không giảm giá đơn hàng

    double amountEligibleForDiscount = 0.0;
    
    // Lấy danh sách các món hàng ĐƯỢC CHỌN
    final selectedItems = _cart.items.where((item) => item.isSelected);

    // TRƯỜNG HỢP 1: Mã áp dụng cho TOÀN BỘ (targetCategories rỗng)
    if (_appliedCoupon!.targetCategories.isEmpty) {
      amountEligibleForDiscount = subtotal;
    } 
    // TRƯỜNG HỢP 2: Mã áp dụng cho DANH MỤC CỤ THỂ
    else {
      for (var item in selectedItems) {
        bool isMatch = false;

        // --- CÁCH 1: So sánh subCategory (Không phân biệt hoa thường) ---
        // Ví dụ: Voucher "Áo" vẫn ăn với sản phẩm loại "áo" hoặc " ÁO "
        if (_appliedCoupon!.targetCategories.any((cat) => 
            cat.trim().toLowerCase() == item.subCategory.trim().toLowerCase())) {
          isMatch = true;
        }

        // --- CÁCH 2: So sánh Tên sản phẩm (Thông minh) ---
        // Nếu subCategory bị rỗng (do quên nhập liệu), nhưng tên sản phẩm là "Áo vest"
        // và voucher áp dụng cho "Áo" -> Vẫn cho giảm giá.
        if (!isMatch) {
           if (_appliedCoupon!.targetCategories.any((cat) => 
              item.productName.toLowerCase().contains(cat.trim().toLowerCase()))) {
             isMatch = true;
           }
        }

        if (isMatch) {
          amountEligibleForDiscount += item.totalPrice;
        }
      }
    }

    // Nếu không có món nào được giảm (amountEligibleForDiscount = 0)
    if (amountEligibleForDiscount == 0) return 0;

    double finalDiscount = 0.0;
    
    // Tính toán dựa trên loại (Percent hoặc Fixed)
    if (_appliedCoupon!.discountType == 'percent') {
      finalDiscount = amountEligibleForDiscount * (_appliedCoupon!.discountValue / 100);
      // Kiểm tra giảm tối đa (Max Discount)
      if (_appliedCoupon!.maxDiscount != null && finalDiscount > _appliedCoupon!.maxDiscount!) {
        finalDiscount = _appliedCoupon!.maxDiscount!;
      }
    } else {
      // Fixed amount
      finalDiscount = _appliedCoupon!.discountValue;
    }

    // Không bao giờ giảm quá tổng tiền hàng (tránh số âm)
    return finalDiscount > subtotal ? subtotal : finalDiscount;
  }

  // Tổng tiền cuối cùng khách phải trả
  double get totalAmount {
    double total = subtotal - discountAmount; 
    return total > 0 ? total : 0;
  }

  // [MỚI] Tổng thanh toán cuối cùng (Bao gồm ship và giảm giá ship)
  double get finalTotalAmount {
    double total = subtotal - discountAmount + (_shippingFee - shippingDiscountAmount);
    return total > 0 ? total : 0;
  }

  // Hàm áp dụng mã
  Future<void> applyCoupon(String code) async {
    _couponError = null;
    notifyListeners();

    try {
      // 1. Kiểm tra mã có tồn tại không
      final coupon = await CouponService.instance.validateCoupon(code, subtotal);
      
      if (coupon != null) {
        // 2. Kiểm tra điều kiện đơn tối thiểu
        if (subtotal < coupon.minOrderValue) {
           throw Exception("Đơn hàng chưa đạt tối thiểu ${coupon.minOrderValue}");
        }
        
        _appliedCoupon = coupon;
        notifyListeners();
      }
    } catch (e) {
      _appliedCoupon = null;
      _couponError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow; // Ném lỗi để UI hiển thị Snackbar nếu cần
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponError = null;
    notifyListeners();
  }
  // --- KẾT THÚC LOGIC COUPON ---

  // Các hàm Cart cũ giữ nguyên
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
        tryOnImageUrl: product.tryOnImageUrl,
        subCategory: product.subCategory ?? '', // QUAN TRỌNG: Cần trường này để phân loại khi giảm giá
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String productId, String? size, String? color) {
    _cart.items.removeWhere((item) =>
        item.productId == productId && item.size == size && item.color == color);
    
    // Nếu xóa sản phẩm dẫn đến tổng tiền < minOrderValue của mã giảm giá -> Tự động hủy mã
    if (_appliedCoupon != null && subtotal < _appliedCoupon!.minOrderValue) {
      removeCoupon();
    }
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
    _appliedCoupon = null; // Xóa mã khi xóa giỏ
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
}