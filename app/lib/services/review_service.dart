import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import 'product_service.dart'; // [NEW] to update stats

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Review>> getReviewsStream(String productId) {
    return _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromDoc(doc)).toList());
  }

  /// Lấy danh sách review có hình ảnh
  Stream<List<Review>> getReviewsWithMediaStream(String productId) {
    return _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .where('images', isNotEqualTo: []) // Chỉ lấy review có mảng images khác rỗng
        // Note: Firestore query limitation: order by field involved in inequality filter first.
        // So we might need to sort client side or ensure index exists.
        // Simple workaround: Filter client side if dataset is small, or strictly follow Firestore rules.
        // For 'images' which is an array, 'isNotEqualTo: []' works but ordering might be tricky.
        // Let's rely on basic query and client filter if complex.
        // BETTER APPROACH for minimal config: Get all and filter/sort.
        // BUT for scalability:
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs.map((doc) => Review.fromDoc(doc)).toList();
          return reviews.where((r) => r.images.isNotEmpty).toList();
        });
  }

  Future<void> addReview(Review review) async {
    await _db.collection('reviews').doc(review.id).set(review.toMap());
    
    // [NEW] Trigger recalculation of product stats
    await ProductService.instance.updateReviewStats(review.productId);
  }
  
  /// Tăng helpful count
  Future<void> likeReview(String reviewId) async {
    await _db.collection('reviews').doc(reviewId).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }
}
