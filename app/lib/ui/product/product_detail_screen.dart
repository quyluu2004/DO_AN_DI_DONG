import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../theme/app_theme.dart';
import '../cart/cart_screen.dart';

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
                      Consumer<FavoriteProvider>(
                        builder: (context, favoriteProvider, child) {
                          final isFavorite = favoriteProvider.isFavorite(widget.product.id);
                          return IconButton(
                            onPressed: () => favoriteProvider.toggleFavorite(widget.product.id),
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.black,
                            ),
                          );
                        },
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
                  
                  // Reviews Section [NEW]


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
}


