import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CouponService {
  // Singleton pattern
  static final CouponService instance = CouponService._();
  CouponService._();

  // Reference tới collection 'coupons' trên Firebase
  final CollectionReference _couponsRef = FirebaseFirestore.instance.collection('coupons');

  // 1. Hàm lấy Stream danh sách mã (Dùng cho Admin hiển thị Realtime)
  Stream<List<CouponModel>> getCouponsStream() {
    return _couponsRef
        .orderBy('startDate', descending: true) // Sắp xếp theo ngày mới nhất
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CouponModel.fromDoc(doc);
      }).toList();
    });
  }

  // 1.1 Hàm lấy danh sách Flash Sale (Dùng cho Home Page)
  Stream<List<CouponModel>> getFlashSaleCoupons() {
    return _couponsRef
        .where('isFlashSale', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CouponModel.fromDoc(doc)).toList();
    });
  }

  // 2. Hàm thêm mã mới
  Future<void> addCoupon(CouponModel coupon) async {
    // Lưu ý: toMap() ở đây lấy từ Model, không cần truyền ID vì Firestore tự tạo
    await _couponsRef.add(coupon.toMap());
  }

  // 3. Hàm xóa mã
  Future<void> deleteCoupon(String id) async {
    await _couponsRef.doc(id).delete();
  }

  // 4. Hàm cập nhật trạng thái (Bật/Tắt)
  Future<void> updateCouponStatus(String id, bool isActive) async {
    await _couponsRef.doc(id).update({'isActive': isActive});
  }

  // 5. Hàm Validate mã (Dùng cho User khi checkout)
  Future<CouponModel?> validateCoupon(String code, double orderTotal) async {
    try {
      final query = await _couponsRef
          .where('code', isEqualTo: code.toUpperCase()) // So sánh mã viết hoa
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception("Mã giảm giá không tồn tại");
      }

      final coupon = CouponModel.fromDoc(query.docs.first);
      final now = DateTime.now();

      // Kiểm tra ngày bắt đầu
      if (now.isBefore(coupon.startDate)) {
        throw Exception("Mã này chưa đến thời gian áp dụng");
      }

      // Kiểm tra ngày hết hạn
      if (now.isAfter(coupon.endDate)) {
        throw Exception("Mã giảm giá đã hết hạn");
      }
      
      // Kiểm tra đơn tối thiểu (Logic này nên check lại ở Provider cho chắc)
      if (orderTotal < coupon.minOrderValue) {
         throw Exception("Đơn hàng chưa đạt giá trị tối thiểu");
      }

      // Kiểm tra User cho phép (Private Voucher)
      if (coupon.allowedUserIds.isNotEmpty) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null || !coupon.allowedUserIds.contains(currentUser.uid)) {
          throw Exception("Mã này không áp dụng cho tài khoản của bạn");
        }
      }

      return coupon;
    } catch (e) {
      rethrow;
    }
  }

  // 6. Lấy tất cả coupon (Future - dùng cho Admin select list)
  Future<List<CouponModel>> getAllCoupons() async {
    final snapshot = await _couponsRef.orderBy('created_at', descending: true).get();
    // Note: Nếu không có field created_at thì bỏ orderBy hoặc thêm vào model
    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs.map((doc) => CouponModel.fromDoc(doc)).toList();
  }

  // 7. Lấy danh sách coupon theo List ID (Dùng cho User nhận quà)
  Future<List<CouponModel>> getCouponsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    // Firestore whereIn giới hạn 10 phần tử, nếu nhiều hơn cần chia mảng
    // Ở đây giả sử số lượng quà tặng nhỏ (<10)
    final snapshot = await _couponsRef
        .where(FieldPath.documentId, whereIn: ids)
        .get();
        
    return snapshot.docs.map((doc) => CouponModel.fromDoc(doc)).toList();
  }
}