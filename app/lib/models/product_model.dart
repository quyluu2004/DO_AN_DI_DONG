import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái sản phẩm
enum ProductStatus {
  active, // Đang bán
  hidden, // Tạm ẩn
  outOfStock, // Hết hàng
  violation, // Vi phạm
  draft, // Nháp
}

/// Extension để convert enum sang string và ngược lại
extension ProductStatusExtension on ProductStatus {
  String get value {
    switch (this) {
      case ProductStatus.active:
        return 'active';
      case ProductStatus.hidden:
        return 'hidden';
      case ProductStatus.outOfStock:
        return 'out_of_stock';
      case ProductStatus.violation:
        return 'violation';
      case ProductStatus.draft:
        return 'draft';
    }
  }

  static ProductStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ProductStatus.active;
      case 'hidden':
        return ProductStatus.hidden;
      case 'out_of_stock':
        return ProductStatus.outOfStock;
      case 'violation':
        return ProductStatus.violation;
      case 'draft':
        return ProductStatus.draft;
      default:
        return ProductStatus.draft;
    }
  }
}

/// Thông tin vi phạm của sản phẩm
class ProductViolation {
  final String reason; // Lý do vi phạm
  final DateTime violatedAt; // Ngày bị vi phạm
  final String? adminNote; // Ghi chú từ admin
  final String status; // 'pending' | 'submitted' | 'resolved'

  ProductViolation({
    required this.reason,
    required this.violatedAt,
    this.adminNote,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'reason': reason,
      'violatedAt': Timestamp.fromDate(violatedAt),
      'adminNote': adminNote,
      'status': status,
    };
  }

  factory ProductViolation.fromMap(Map<String, dynamic> map) {
    return ProductViolation(
      reason: map['reason'] as String? ?? '',
      violatedAt: (map['violatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminNote: map['adminNote'] as String?,
      status: map['status'] as String? ?? 'pending',
    );
  }
}

/// Biến thể sản phẩm (SKU Matrix: Màu x Size)
class ProductVariant {
  final String id;
  final String sku;
  final String? color; // Màu sắc (Vd: Đỏ)
  final String? size;  // Kích thước (Vd: XL)
  final int price;     // Giá bán riêng cho biến thể này
  final int stock;     // Tồn kho riêng
  final String? imageUrl; // Ảnh riêng cho biến thể (optional)

  ProductVariant({
    required this.id,
    required this.sku,
    this.color,
    this.size,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'color': color,
      'size': size,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      color: map['color'] as String?,
      size: map['size'] as String?,
      price: (map['price'] as num?)?.toInt() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  ProductVariant copyWith({
    String? id,
    String? sku,
    String? color,
    String? size,
    int? price,
    int? stock,
    String? imageUrl,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      color: color ?? this.color,
      size: size ?? this.size,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Model sản phẩm đầy đủ với tất cả thông tin cần thiết
class Product {
  final String id;
  final String shopId; // ID của shop sở hữu sản phẩm
  
  // Thông tin cơ bản
  final String name;
  final String? description; // Mô tả ngắn
  final String? shortDescription; // Mô tả ngắn gọn
  final int price; // Giá bán (đơn vị: đồng)
  final int stock; // Tồn kho
  final String? category; // Danh mục sản phẩm (Men, Women)
  final String? subCategory; // [NEW] Loại sản phẩm (Top, Bottom, Outerwear, Shoes)
  
  // Hình ảnh
  final List<String> images; // Danh sách URL ảnh
  final int? primaryImageIndex; // Index của ảnh đại diện (0-based)
  final String? tryOnImageUrl; // Ảnh đã tách nền cho Virtual Try-On
  
  // Trạng thái
  final ProductStatus status;
  
  // Thuộc tính/biến thể
  final List<ProductVariant> variants;
  
  // Thông tin vi phạm (nếu có)
  final ProductViolation? violation;
  
  // Thông tin hiệu suất
  final int views; // Lượt xem
  final int sales; // Lượt bán
  final double? averageRating; // Đánh giá trung bình (0.0 - 5.0)
  final int reviewCount; // Số lượng đánh giá
  final Map<String, dynamic>? reviewStats; // [NEW] Aggregate stats: fit distribution etc.
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    this.shortDescription,
    required this.price,
    required this.stock,
    this.category,
    this.subCategory,
    this.images = const [],
    this.primaryImageIndex,
    this.tryOnImageUrl,
    this.status = ProductStatus.draft,
    this.variants = const [],
    this.violation,
    this.views = 0,
    this.sales = 0,
    this.averageRating,
    this.reviewCount = 0,
    this.reviewStats,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Lấy URL ảnh đại diện
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final index = primaryImageIndex ?? 0;
    if (index >= 0 && index < images.length) {
      return images[index];
    }
    return images.first;
  }

  /// Kiểm tra sản phẩm có đang bán không
  bool get isActive => status == ProductStatus.active;

  /// Kiểm tra sản phẩm có vi phạm không
  bool get hasViolation => status == ProductStatus.violation || violation != null;

  /// Kiểm tra sản phẩm có hết hàng không
  bool get isOutOfStock => stock <= 0 || status == ProductStatus.outOfStock;

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'price': price,
      'stock': stock,
      'category': category,
      'subCategory': subCategory,
      'images': images,
      'primaryImageIndex': primaryImageIndex,
      'tryOnImageUrl': tryOnImageUrl,
      'status': status.value,
      'variants': variants.map((v) => v.toMap()).toList(),
      'violation': violation?.toMap(),
      'views': views,
      'sales': sales,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'reviewStats': reviewStats,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Tạo Product từ Firestore document
  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Parse variants
    final variantsList = data['variants'] as List<dynamic>? ?? [];
    final variants = variantsList
        .map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
        .toList();
    
    // Parse violation
    ProductViolation? violation;
    if (data['violation'] != null) {
      violation = ProductViolation.fromMap(
        data['violation'] as Map<String, dynamic>,
      );
    }
    
    return Product(
      id: doc.id,
      shopId: data['shopId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      shortDescription: data['shortDescription'] as String?,
      price: (data['price'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      category: data['category'] as String?,
      subCategory: data['subCategory'] as String?,
      images: List<String>.from(data['images'] as List<dynamic>? ?? []),
      primaryImageIndex: data['primaryImageIndex'] as int?,
      tryOnImageUrl: data['tryOnImageUrl'] as String?,
      status: ProductStatusExtension.fromString(
        data['status'] as String? ?? 'draft',
      ),
      variants: variants,
      violation: violation,
      views: (data['views'] as num?)?.toInt() ?? 0,
      sales: (data['sales'] as num?)?.toInt() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      reviewStats: data['reviewStats'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Tạo bản copy với một số thay đổi
  Product copyWith({
    String? id,
    String? shopId,
    String? name,
    String? description,
    String? shortDescription,
    int? price,
    int? stock,
    String? category,
    String? subCategory, // [NEW] Added for Try-On (Top, Bottom, etc.)
    List<String>? images,
    int? primaryImageIndex,
    String? tryOnImageUrl,
    ProductStatus? status,
    List<ProductVariant>? variants,
    ProductViolation? violation,
    int? views,
    int? sales,
    double? averageRating,
    int? reviewCount,
    Map<String, dynamic>? reviewStats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      images: images ?? this.images,
      primaryImageIndex: primaryImageIndex ?? this.primaryImageIndex,
      tryOnImageUrl: tryOnImageUrl ?? this.tryOnImageUrl,
      status: status ?? this.status,
      variants: variants ?? this.variants,
      violation: violation ?? this.violation,
      views: views ?? this.views,
      sales: sales ?? this.sales,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      reviewStats: reviewStats ?? this.reviewStats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

