import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import 'admin_product_edit_screen.dart';
import 'add_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService _productService = ProductService.instance;
  String _searchQuery = '';
  ProductStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, SKU...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<ProductStatus?>(
                value: _filterStatus,
                hint: const Text('Tất cả trạng thái'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                  ...ProductStatus.values.map((s) => DropdownMenuItem(
                    value: s, 
                    child: Text(s.toString().split('.').last.toUpperCase()),
                  )),
                ],
                onChanged: (val) => setState(() => _filterStatus = val),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminProductEditScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm sản phẩm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _searchQuery.isEmpty
                  ? _productService.getProductsStream(status: _filterStatus)
                  : _productService.searchProducts(searchQuery: _searchQuery, status: _filterStatus),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: Colors.black26),
                        SizedBox(height: 12),
                        Text('Chưa có sản phẩm nào', style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[200]!)),
                  child: ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                            image: product.images.isNotEmpty
                                ? DecorationImage(image: NetworkImage(product.images.first), fit: BoxFit.cover)
                                : null,
                          ),
                          child: product.images.isEmpty ? const Icon(Icons.image_not_supported) : null,
                        ),
                        title: Row(
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            _StatusBadge(status: product.status),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${product.category ?? 'Uncategorized'} • ${product.variants.length} biến thể'),
                            Text('Tồn kho: ${product.stock} • Đã bán: ${product.sales}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'đ ${product.price}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AdminProductEditScreen(product: product)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _productService.deleteProduct(product.id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProductStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case ProductStatus.active:
        color = Colors.green;
        label = 'Đang bán';
        break;
      case ProductStatus.hidden:
        color = Colors.grey;
        label = 'Đang ẩn';
        break;
      case ProductStatus.outOfStock:
        color = Colors.orange;
        label = 'Hết hàng';
        break;
      case ProductStatus.violation:
        color = Colors.red;
        label = 'Vi phạm';
        break;
      case ProductStatus.draft:
        color = Colors.blueGrey;
        label = 'Nháp';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
