import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import 'product_service.dart';
import '../models/product_model.dart';

class ReviewService {
  ReviewService._internal();
  static final ReviewService instance = ReviewService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsCol =>
      _db.collection('reviews');

  /// Thêm đánh giá mới
  Future<void> addReview(ReviewModel review) async {
    // 1. Thêm review vào collection 'reviews'
    await _reviewsCol.add(review.toMap());

    // 2. Tính toán lại rating trung bình cho sản phẩm
    // Lưu ý: Đây là cách client-side đơn giản. Tốt hơn nên dùng Cloud Functions.
    await _updateProductRating(review.productId);
  }

  /// Lấy danh sách đánh giá của 1 sản phẩm
  Stream<List<ReviewModel>> getReviewsStream(String productId) {
    return _reviewsCol
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ReviewModel.fromDoc).toList());
  }

  /// Cập nhật rating trung bình
  Future<void> _updateProductRating(String productId) async {
    final snapshot = await _reviewsCol.where('productId', isEqualTo: productId).get();
    final reviews = snapshot.docs.map(ReviewModel.fromDoc).toList();

    if (reviews.isEmpty) return;

    final totalRating = reviews.fold(0.0, (sum, r) => sum + r.rating);
    final averageRating = totalRating / reviews.length;

    // Cập nhật vào Product
    await ProductService.instance.updateProduct(productId, {
      'averageRating': averageRating,
      'reviewCount': reviews.length,
    });
  }
}
