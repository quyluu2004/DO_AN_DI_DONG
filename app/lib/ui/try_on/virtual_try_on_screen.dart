
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../providers/cart_provider.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final List<Product>? initialProducts; // [NEW]
  const VirtualTryOnScreen({super.key, this.initialProducts});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  // 1. State Management
  Product? _selectedTop;
  Product? _selectedBottom;
  Product? _selectedOuterwear;
  Product? _selectedShoes;

  // Matrices for gestures (Position, Scale, Rotation)
  final ValueNotifier<Matrix4> _topMatrix = ValueNotifier(Matrix4.identity());
  final ValueNotifier<Matrix4> _bottomMatrix = ValueNotifier(Matrix4.identity());
  final ValueNotifier<Matrix4> _outerwearMatrix = ValueNotifier(Matrix4.identity());
  final ValueNotifier<Matrix4> _shoesMatrix = ValueNotifier(Matrix4.identity());


  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      for (var p in widget.initialProducts!) {
        // Auto-select based on subCategory
        if (p.subCategory != null) {
           _onSelectProduct(p, p.subCategory!.toLowerCase());
        }
      }
    }
  }

  void _onSelectProduct(Product product, String type) {
    // Map Firestore values to internal keys if needed
    // Assuming 'Top' -> 'top' (lowercase match)
    final key = type.toLowerCase();
    setState(() {
      switch (type) {
        case 'top':
          _selectedTop = product;
          // Reset matrix when new item selected
          _topMatrix.value = Matrix4.identity(); 
          break;
        case 'bottom':
          _selectedBottom = product;
          _bottomMatrix.value = Matrix4.identity();
          break;
        case 'outerwear':
          _selectedOuterwear = product;
          _outerwearMatrix.value = Matrix4.identity();
          break;
        case 'shoes':
          _selectedShoes = product;
          _shoesMatrix.value = Matrix4.identity();
          break;
      }
    });
  }

  void _resetAll() {
    setState(() {
      _selectedTop = null;
      _selectedBottom = null;
      _selectedOuterwear = null;
      _selectedShoes = null;
      _topMatrix.value = Matrix4.identity();
      _bottomMatrix.value = Matrix4.identity();
      _outerwearMatrix.value = Matrix4.identity();
      _shoesMatrix.value = Matrix4.identity();
    });
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    int count = 0;
    if (_selectedTop != null) { cartProvider.addToCart(_selectedTop!); count++; }
    if (_selectedBottom != null) { cartProvider.addToCart(_selectedBottom!); count++; }
    if (_selectedOuterwear != null) { cartProvider.addToCart(_selectedOuterwear!); count++; }
    if (_selectedShoes != null) { cartProvider.addToCart(_selectedShoes!); count++; }

    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm $count sản phẩm vào giỏ!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa chọn món nào để thêm!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Thử Đồ Ảo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add), // Import from Cart icon
            tooltip: 'Lấy đồ từ Giỏ hàng',
            onPressed: () {
              showModalBottomSheet(
                context: context, 
                builder: (ctx) => _CartImportSheet(
                  onSelect: (p) {
                    if (p.subCategory != null) {
                      _onSelectProduct(p, p.subCategory!.toLowerCase());
                      Navigator.pop(ctx);
                    }
                  }
                )
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetAll),
          IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: _addToCart),
        ],
      ),
      body: Column(
        children: [
          // --- 2.1 The Canvas (Flex 6) ---
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.grey[100],
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Placeholder Body/Model
                   Center(
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        'assets/images/model_placeholder.png', // Ensure you have this or use Icon
                        errorBuilder: (_,__,___) => const Icon(Icons.person, size: 300, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Order: Shoes -> Bottom -> Top -> Outerwear
                  if (_selectedShoes?.tryOnImageUrl != null)
                    DraggableItem(
                      imageUrl: _selectedShoes!.tryOnImageUrl!,
                      matrixNotifier: _shoesMatrix,
                    ),
                  
                  if (_selectedBottom?.tryOnImageUrl != null)
                    DraggableItem(
                      imageUrl: _selectedBottom!.tryOnImageUrl!,
                      matrixNotifier: _bottomMatrix,
                    ),

                  if (_selectedTop?.tryOnImageUrl != null)
                    DraggableItem(
                      imageUrl: _selectedTop!.tryOnImageUrl!,
                      matrixNotifier: _topMatrix,
                    ),

                  if (_selectedOuterwear?.tryOnImageUrl != null)
                    DraggableItem(
                      imageUrl: _selectedOuterwear!.tryOnImageUrl!,
                      matrixNotifier: _outerwearMatrix,
                    ),
                ],
              ),
            ),
          ),

          // --- 2.2 The Selector (Flex 4) ---
          Expanded(
            flex: 4,
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Áo (Top)'),
                        Tab(text: 'Quần (Bot)'),
                        Tab(text: 'Khoác'),
                        Tab(text: 'Giày'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ProductGrid(category: 'Top', onSelect: (p) => _onSelectProduct(p, 'top')),
                        _ProductGrid(category: 'Bottom', onSelect: (p) => _onSelectProduct(p, 'bottom')),
                        _ProductGrid(category: 'Outerwear', onSelect: (p) => _onSelectProduct(p, 'outerwear')),
                        _ProductGrid(category: 'Shoes', onSelect: (p) => _onSelectProduct(p, 'shoes')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. Draggable Item Widget ---
class DraggableItem extends StatelessWidget {
  final String imageUrl;
  final ValueNotifier<Matrix4> matrixNotifier;

  const DraggableItem({
    super.key,
    required this.imageUrl,
    required this.matrixNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder listens to changes in the matrix
    return ValueListenableBuilder<Matrix4>(
      valueListenable: matrixNotifier,
      builder: (context, matrix, child) {
        return MatrixGestureDetector(
          shouldRotate: true,
          shouldScale: true,
          shouldTranslate: true,
          onMatrixUpdate: (m, tm, sm, rm) {
            matrixNotifier.value = m;
          },
          child: Transform(
            transform: matrix,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              // width: 200, // Optional initial size
            ),
          ),
        );
      },
    );
  }
}

// --- Sub-widget: Product Grid ---
class _ProductGrid extends StatelessWidget {
  final String category;
  final Function(Product) onSelect;

  const _ProductGrid({required this.category, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Map UI category labels to DB values if needed, for now assuming direct match or simple logic
    // Or better: fetch all and filter in memory or query carefully.
    // Assuming 'category' field in Firestore matches somewhat.
    
    return StreamBuilder<List<Product>>(
      stream: ProductService.instance.getProductsStream(), // Or a filtered stream
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snapshot.hasData) {
           debugPrint('DEBUG TRY-ON: Total products fetched: ${snapshot.data!.length}');
           for (var p in snapshot.data!) {
             debugPrint('  - Product: ${p.name}, subCategory: ${p.subCategory}');
           }
        }
        
        // Client-side filter using new subCategory field
        final products = snapshot.data!.where((p) {
           if (p.subCategory == null) return false;
           // Flexible matching (case-insensitive)
           final sub = p.subCategory!.toLowerCase();
           final target = category.toLowerCase();
           final match = sub == target; 
           if (match) debugPrint('    -> MATCH FOUND: ${p.name} for category $target');
           return match;
        }).toList();

        if (products.isEmpty) return const Center(child: Text('Không có sản phẩm nào.'));

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () => onSelect(product),
              child: Card(
                elevation: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: product.tryOnImageUrl != null && product.tryOnImageUrl!.isNotEmpty
                        ? Image.network(product.tryOnImageUrl!, fit: BoxFit.contain)
                        : (product.images.isNotEmpty ? Image.network(product.images.first, fit: BoxFit.cover) : const Icon(Icons.image)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CartImportSheet extends StatelessWidget {
  final Function(Product) onSelect;

  const _CartImportSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Access CartProvider
    final cartItems = Provider.of<CartProvider>(context, listen: false)
        .cart.items
        .where((item) => item.tryOnImageUrl != null && item.tryOnImageUrl!.isNotEmpty)
        .toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chọn từ Giỏ hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (cartItems.isEmpty)
            const Center(child: Text('Không có sản phẩm nào hỗ trợ Try-On trong giỏ.', style: TextStyle(color: Colors.grey)))
          else
            Expanded(
              child: ListView.separated(
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(item.productName),
                    subtitle: Text('${item.subCategory ?? ''} - ${item.color ?? ''} / ${item.size ?? ''}'),
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      // Convert CartItem back to Product
                      final product = Product(
                         id: item.productId, 
                         shopId: '', 
                         name: item.productName, 
                         price: item.price.toInt(), 
                         stock: 1, 
                         createdAt: DateTime.now(), 
                         updatedAt: DateTime.now(),
                         images: [item.imageUrl],
                         tryOnImageUrl: item.tryOnImageUrl,
                         subCategory: item.subCategory,
                      );
                      onSelect(product);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
