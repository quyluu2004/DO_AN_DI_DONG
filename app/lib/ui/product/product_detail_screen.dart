
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart'; // [NEW]
import '../../services/review_service.dart'; // [NEW]
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  int _currentImageIndex = 0;

  // Lists will be populated from product variants
  List<String> _sizes = [];
  List<String> _colors = [];

  @override
  void initState() {
    super.initState();
    // Populate sizes and colors from actual variants
    if (widget.product.variants.isNotEmpty) {
      final uniqueSizes = <String>{};
      final uniqueColors = <String>{};
      
      for (var variant in widget.product.variants) {
        if (variant.size != null && variant.size!.isNotEmpty) {
          uniqueSizes.add(variant.size!);
        }
        if (variant.color != null && variant.color!.isNotEmpty) {
          uniqueColors.add(variant.color!);
        }
      }
      
      setState(() {
        _sizes = uniqueSizes.toList()..sort();
        _colors = uniqueColors.toList();
      });
    }
  }

  void _addToCart() {
    // Only validate if variants exist
    if (_sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn kích thước trước!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_colors.isNotEmpty && _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn màu sắc trước!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Attempting to add to cart: ${widget.product.name}');
    
    final cartProvider = context.read<CartProvider>();
    cartProvider.addToCart(
      widget.product,
      size: _selectedSize,
      color: _selectedColor,
      quantity: _quantity,
    );

    print('Added to cart. Current items: ${cartProvider.itemCount}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã thêm thành công! Giỏ hàng: ${cartProvider.itemCount} món'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'XEM GIỎ',
          textColor: Colors.white,
          onPressed: () => Navigator.pop(context), // Go back (likely to home/cart)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. App Bar & Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: product.images.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          itemCount: product.images.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              product.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
                            );
                          },
                        ),
                        if (product.images.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${product.images.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: AppColors.border,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.share_outlined, color: Colors.black),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.name}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'đ ${product.price}', // Cần format currency
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    product.description ?? 'Chưa có mô tả',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Size Selector
                  Text('Kích thước', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _sizes.map((s) {
                      final isSelected = _selectedSize == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedSize = selected ? s : null);
                        },
                        selectedColor: AppColors.charcoal,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color Selector
                  Text('Màu sắc', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _colors.map((c) {
                      final isSelected = _selectedColor == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedColor = selected ? c : null);
                        },
                        selectedColor: AppColors.charcoal,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),

                  // Reviews Section
                  _buildReviewsSection(product),
                  
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                      icon: const Icon(Icons.remove, size: 16),
                    ),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                      icon: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Thêm vào giỏ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         _buildReviewsHeader(product),
         const SizedBox(height: 24),
         _buildReviewList(product.id),
      ],
    );
  }

  Widget _buildReviewsHeader(Product product) {
    // 1. Calculate Stats from Product Model
    final rating = product.averageRating ?? 0.0;
    final count = product.reviewCount;
    final stats = product.reviewStats;
    
    // Default fit stats if null
    double smallPct = 0.0;
    double truePct = 1.0; // Default to perfect fit if no data
    double largePct = 0.0;
    
    if (stats != null && stats['fit'] != null) {
      final fit = stats['fit'];
      smallPct = (fit['small'] as num?)?.toDouble() ?? 0.0;
      truePct = (fit['trueToSize'] as num?)?.toDouble() ?? 0.0;
      largePct = (fit['large'] as num?)?.toDouble() ?? 0.0;
    } else if (count > 0) {
       // Fallback if we have reviews but no stats yet (shouldn't happen if logic is correct)
       truePct = 1.0;
    } else {
       // No reviews
       truePct = 0.0; // Don't show misleading bars
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & View All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đánh giá ($count)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                 // Implement "View All Reviews" screen navigation if needed
              }, 
              child: const Text('Xem tất cả >', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        
        // Rating Big Number
        Row(
          children: [
            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                ),
                const SizedBox(height: 4),
                const Text('Khách hàng hài lòng', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Fit Bars
        const Text('Sản phẩm có vừa không?', style: TextStyle(color: Colors.black)),
        const SizedBox(height: 8),
        _buildVisualFitBar('Nhỏ', smallPct),
        _buildVisualFitBar('Chuẩn size', truePct),
        _buildVisualFitBar('Lớn', largePct),
      ],
    );
  }

  // State for Review Filtering
  bool _filterWithPicture = false;
  int? _filterStar; // null = all

  Widget _buildReviewList(String productId) {
     return Column(
       children: [
         // Filter Bar using StreamBuilder/State is tricky if mixed. 
         // For now, simple filter UI trigger
         Row(
           children: [
             InkWell(
               onTap: _showFilterModal,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                 child: Row(
                   children: [
                     const Text('Lọc'),
                     const SizedBox(width: 4),
                     Icon(Icons.filter_list, size: 16, color: _filterWithPicture || _filterStar != null ? Colors.black : Colors.grey),
                   ],
                 ),
               ),
             ),
             const SizedBox(width: 12),
             if (_filterWithPicture)
                _buildActiveFilterChip('Có hình ảnh', () => setState(() => _filterWithPicture = false)),
             if (_filterStar != null)
                _buildActiveFilterChip('${_filterStar} Sao', () => setState(() => _filterStar = null)),
           ],
         ),
         const SizedBox(height: 16),

         StreamBuilder<List<Review>>(
          // ReviewService should likely support query params for creating specific streams, 
          // or we filter client side here for simplicity as discussed.
          stream: ReviewService().getReviewsStream(productId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Lỗi: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            var reviews = snapshot.data ?? [];
            
            // Client-side Filtering
            if (_filterWithPicture) {
              reviews = reviews.where((r) => r.images.isNotEmpty).toList();
            }
            if (_filterStar != null) {
              reviews = reviews.where((r) => r.rating >= _filterStar! && r.rating < _filterStar! + 1).toList();
            }

            if (reviews.isEmpty) return const Text('Không tìm thấy đánh giá phù hợp.');

            return Column(
              children: reviews.take(5).map((r) => _buildReviewItem(r)).toList(), // Limit to 5 in preview
            );
          },
         ),
       ],
     );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14)),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('Bộ lọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(height: 24),
                
                const Text('Hình ảnh'),
                const SizedBox(height: 8),
                ChoiceChip(
                  label: const Text('Có hình ảnh'),
                  selected: _filterWithPicture,
                  onSelected: (val) {
                    setModalState(() => _filterWithPicture = val);
                    setState(() {}); // Update parent
                  },
                ),
                
                const SizedBox(height: 16),
                const Text('Đánh giá'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    return ChoiceChip(
                      label: Text('$star Sao'),
                      selected: _filterStar == star,
                      onSelected: (val) {
                         setModalState(() => _filterStar = val ? star : null);
                         setState(() {}); // Update parent
                      },
                    );
                  }),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Xong'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundImage: review.userAvatar != null ? NetworkImage(review.userAvatar!) : null,
                backgroundColor: Colors.grey[200],
                child: review.userAvatar == null ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A') : null,
              ),
              const SizedBox(width: 8),
              // Name & Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_maskName(review.userName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < review.rating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      )),
                    )
                  ],
                ),
              ),
              Text(DateFormat('dd MMM yyyy').format(review.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          
          // Variant Info
          if (review.color != null || review.size != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Màu: ${review.color ?? '-'} / Size: ${review.size ?? '-'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          
          // Body Stats Tag (if available) - Mimicking "Keep Warm (44)" style or just plain text
          if (review.fitRating != FitRating.trueToSize) 
             Container(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
               child: Text('Độ vừa: ${review.fitRating == FitRating.small ? "Hơi chật" : "Hơi rộng"}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
             ),

          // Content
          Text(review.comment),
          
          // Images
          if (review.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: review.images.map((img) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                       onTap: () {
                         // Open full image viewer
                       },
                       child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(img, width: 100, height: 100, fit: BoxFit.cover),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            
          // Helpful
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                   ReviewService().likeReview(review.id);
                   // Optimistic update could happen here or rely on Stream
                },
                child: const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
              ),
              const SizedBox(width: 4),
              Text('Hữu ích (${review.helpfulCount})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  String _maskName(String name) {
    if (name.isEmpty) return '***';
    if (name.length <= 2) return name;
    return '${name[0]}***${name[name.length - 1]}';
  }

  Widget _buildVisualFitBar(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(
            child: Stack(
              children: [
                Container(height: 4, color: Colors.grey[200]), // Background
                FractionallySizedBox(widthFactor: percent > 1.0 ? 1.0 : percent, child: Container(height: 4, color: Colors.black)), // Foreground
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
} // End of State class
