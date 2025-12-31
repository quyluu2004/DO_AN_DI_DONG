import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

/// Service quản lý sản phẩm (D2C)
/// 
/// Cung cấp các chức năng truy xuất sản phẩm cho người dùng
class ProductService {
  ProductService._internal();

  static final ProductService instance = ProductService._internal();

  final _db = FirebaseFirestore.instance;
  // Revert to fixed shopID as per original design. 
  // The permission error was likely just due to missing Auth, not ID mismatch.
  final String _shopId = 'official_store';

  /// Reference đến global collection products
  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _db.collection('products');

  /// Thêm sản phẩm mới
  /// 
  /// [product] - Thông tin sản phẩm cần thêm
  /// Trả về ID của sản phẩm vừa tạo
  Future<String> addProduct(Product product) async {
    final now = DateTime.now();
    final productData = product.copyWith(
      shopId: _shopId,
      createdAt: now,
      updatedAt: now,
    ).toMap();

    final docRef = await _productsCol.add(productData);
    return docRef.id;
  }

  /// Cập nhật sản phẩm
  /// 
  /// [productId] - ID của sản phẩm cần cập nhật
  /// [updates] - Map chứa các trường cần cập nhật
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _productsCol.doc(productId).update(updates);
  }

  /// Xóa sản phẩm
  /// 
  /// [productId] - ID của sản phẩm cần xóa
  Future<void> deleteProduct(String productId) async {
    await _productsCol.doc(productId).delete();
  }

  /// Lấy thông tin một sản phẩm theo ID
  /// 
  /// [productId] - ID của sản phẩm
  Future<Product?> getProduct(String productId) async {
    final doc = await _productsCol.doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  /// Stream danh sách tất cả sản phẩm của shop hiện tại
  /// 
  /// [status] - Lọc theo trạng thái (null = tất cả)
  /// [sortBy] - Sắp xếp theo: 'createdAt', 'sales', 'stock' (mặc định: 'createdAt')
  /// [ascending] - Sắp xếp tăng dần hay giảm dần (mặc định: false = giảm dần)
  Stream<List<Product>> getProductsStream({
    ProductStatus? status,
    String sortBy = 'createdAt',
    bool ascending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _productsCol;

    // Filter theo status
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    // Sort
    switch (sortBy) {
      case 'sales':
        query = query.orderBy('sales', descending: !ascending);
        break;
      case 'stock':
        query = query.orderBy('stock', descending: ascending);
        break;
      case 'createdAt':
      default:
        query = query.orderBy('createdAt', descending: !ascending);
        break;
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(Product.fromDoc).toList(),
    );
  }

  /// Tìm kiếm sản phẩm theo tên
  /// 
  /// [searchQuery] - Từ khóa tìm kiếm
  /// [status] - Lọc theo trạng thái (null = tất cả)
  Stream<List<Product>> searchProducts({
    required String searchQuery,
    ProductStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _productsCol;

    // Filter theo status nếu có
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    // Note: Firestore không hỗ trợ full-text search tốt
    // Trong production nên dùng Algolia hoặc Elasticsearch
    // Ở đây ta sẽ filter ở client side sau khi lấy dữ liệu
    return query.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        final products = snapshot.docs.map(Product.fromDoc).toList();
        final queryLower = searchQuery.toLowerCase();
        return products.where((p) {
          return p.name.toLowerCase().contains(queryLower) ||
              (p.description?.toLowerCase().contains(queryLower) ?? false) ||
              (p.shortDescription?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
      },
    );
  }

  /// Lấy danh sách sản phẩm vi phạm
  Stream<List<Product>> getViolatedProductsStream() {
    return _productsCol
        .where('status', isEqualTo: ProductStatus.violation.value)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Product.fromDoc).toList(),
        );
  }

  /// Cập nhật trạng thái sản phẩm
  /// 
  /// [productId] - ID của sản phẩm
  /// [status] - Trạng thái mới
  Future<void> updateProductStatus(
    String productId,
    ProductStatus status,
  ) async {
    await updateProduct(productId, {'status': status.value});
  }

  /// Ẩn/Hiện sản phẩm
  /// 
  /// [productId] - ID của sản phẩm
  /// [hidden] - true = ẩn, false = hiện
  Future<void> toggleProductVisibility(String productId, bool hidden) async {
    final status = hidden ? ProductStatus.hidden : ProductStatus.active;
    await updateProductStatus(productId, status);
  }

  /// Cập nhật tồn kho
  /// 
  /// [productId] - ID của sản phẩm
  /// [stock] - Số lượng tồn kho mới
  Future<void> updateStock(String productId, int stock) async {
    final updates = <String, dynamic>{
      'stock': stock,
    };

    // Tự động cập nhật status nếu hết hàng
    if (stock <= 0) {
      updates['status'] = ProductStatus.outOfStock.value;
    } else {
      // Nếu đang ở trạng thái out_of_stock và có hàng lại, chuyển về active
      final product = await getProduct(productId);
      if (product?.status == ProductStatus.outOfStock) {
        updates['status'] = ProductStatus.active.value;
      }
    }

    await updateProduct(productId, updates);
  }

  /// Thêm vi phạm cho sản phẩm
  /// 
  /// [productId] - ID của sản phẩm
  /// [violation] - Thông tin vi phạm
  Future<void> addViolation(
    String productId,
    ProductViolation violation,
  ) async {
    await updateProduct(productId, {
      'status': ProductStatus.violation.value,
      'violation': violation.toMap(),
    });
  }

  /// Gửi duyệt lại sản phẩm sau khi sửa vi phạm
  /// 
  /// [productId] - ID của sản phẩm
  Future<void> resubmitProduct(String productId) async {
    // Lấy sản phẩm hiện tại để cập nhật violation status
    final product = await getProduct(productId);
    if (product == null) return;

    final updates = <String, dynamic>{
      'status': ProductStatus.active.value,
    };

    // Cập nhật violation status nếu có violation
    if (product.violation != null) {
      final violationMap = product.violation!.toMap();
      violationMap['status'] = 'submitted';
      updates['violation'] = violationMap;
    }

    await updateProduct(productId, updates);
  }

  /// Tăng lượt xem sản phẩm
  /// 
  /// [productId] - ID của sản phẩm
  Future<void> incrementViews(String productId) async {
    await _productsCol.doc(productId).update({
      'views': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tăng lượt bán sản phẩm
  /// 
  /// [productId] - ID của sản phẩm
  /// [quantity] - Số lượng đã bán (mặc định: 1)
  Future<void> incrementSales(String productId, {int quantity = 1}) async {
    await _productsCol.doc(productId).update({
      'sales': FieldValue.increment(quantity),
      'stock': FieldValue.increment(-quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Kiểm tra và cập nhật status nếu hết hàng
    final product = await getProduct(productId);
    if (product != null && product.stock - quantity <= 0) {
      await updateProductStatus(productId, ProductStatus.outOfStock);
    }
  }

  /// Lấy thống kê sản phẩm
  /// 
  /// Trả về Map chứa các thống kê:
  /// - total: Tổng số sản phẩm
  /// - active: Số sản phẩm đang bán
  /// - hidden: Số sản phẩm tạm ẩn
  /// - outOfStock: Số sản phẩm hết hàng
  /// - violation: Số sản phẩm vi phạm
  Future<Map<String, int>> getProductStats() async {
    final snapshot = await _productsCol.get();
    final products = snapshot.docs.map(Product.fromDoc).toList();

    return {
      'total': products.length,
      'active': products.where((p) => p.status == ProductStatus.active).length,
      'hidden': products.where((p) => p.status == ProductStatus.hidden).length,
      'outOfStock': products
          .where((p) => p.status == ProductStatus.outOfStock)
          .length,
      'violation': products
          .where((p) => p.status == ProductStatus.violation)
          .length,
    };
  }
  /// Lấy danh sách danh mục duy nhất từ các sản phẩm hiện có
  Future<List<String>> getUniqueCategories() async {
    final snapshot = await _productsCol.get();
    final categories = snapshot.docs
        .map((doc) => doc.data()['category'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    
    // Sort categories alphabetically or customized logic
    categories.sort();
    return categories;
  }

  /// Lấy sản phẩm Flash Sale (Top bán chạy)
  Stream<List<Product>> getFlashSaleProducts({int limit = 10}) {
    return _productsCol
        .where('status', isEqualTo: ProductStatus.active.value)
        .orderBy('sales', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromDoc).toList());
  }

  /// Lấy 1 sản phẩm đại diện cho category (để lấy ảnh thumbnail)
  Future<Product?> getFirstProductByCategory(String category) async {
    final snapshot = await _productsCol
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: ProductStatus.active.value)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return Product.fromDoc(snapshot.docs.first);
  }


  /// Lấy danh sách sản phẩm theo danh sách ID (dùng cho Favorites)
  Stream<List<Product>> getFavoriteProducts(List<String> productIds) {
    if (productIds.isEmpty) {
      return Stream.value([]);
    }

    // Firestore `whereIn` giới hạn 10 items (not 30, it is 10 for 'in' and 'array-contains-any', but 10 for 'whereIn'? Docs say 10 for OR queries, 30 for IN queries on some platforms, let's play safe or handle batching if needed. For MVP, assuming small list).
    // Actually, documentId with whereIn supports up to 10-30 depending on version.
    // If list is > 10, we might need to split.
    // For simplicity in this project, if the list is huge, we will just fetch chunks.
    // But to keep it extremely simple for now:
    
    // We can't easily stream 'whereIn' > 10 items. 
    // Alternative: Stream ALL active products and filter in memory (not efficient but safe for small apps).
    // OR: Stream chunks.

    // Let's try client-side filter for robustness with small dataset unless requirements say otherwise.
    return _productsCol
        .where('status', isEqualTo: ProductStatus.active.value)
        .snapshots()
        .map((snapshot) {
          final allProducts = snapshot.docs.map(Product.fromDoc).toList();
          return allProducts.where((p) => productIds.contains(p.id)).toList();
        });
  }
}

