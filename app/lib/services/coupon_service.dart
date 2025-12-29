import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  static final CouponService instance = CouponService._();
  CouponService._();

  final _db = FirebaseFirestore.instance;

  Future<void> createCoupon(CouponModel coupon) async {
    await _db.collection('coupons').doc(coupon.id).set(coupon.toMap());
  }

  Future<void> deleteCoupon(String id) async {
    await _db.collection('coupons').doc(id).delete();
  }
  
  Stream<List<CouponModel>> getCouponsStream() {
    return _db.collection('coupons')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CouponModel.fromDoc(doc)).toList());
  }

  Future<CouponModel?> getCouponByCode(String code) async {
    final snapshot = await _db.collection('coupons')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CouponModel.fromDoc(snapshot.docs.first);
    }
    return null;
  }
  
  Future<void> updateCouponStatus(String id, bool isActive) async {
    await _db.collection('coupons').doc(id).update({'isActive': isActive});
  }
}
