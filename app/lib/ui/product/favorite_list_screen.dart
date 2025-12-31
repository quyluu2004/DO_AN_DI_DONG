import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/favorite_provider.dart';
import '../../services/product_service.dart';
import 'product_detail_screen.dart';

class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favProvider, child) {
          final favIds = favProvider.favoriteIds;

          if (favIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('Chưa có sản phẩm yêu thích', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return StreamBuilder<List<Product>>(
            stream: ProductService.instance.getFavoriteProducts(favIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 // Có Ids nhưng không tìm thấy products (có thể đã bị xóa hoặc ẩn)
                 return const Center(child: Text('Không tìm thấy sản phẩm'));
              }

              final products = snapshot.data!;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _FavoriteItem(product: product);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  final Product product;
  const _FavoriteItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: product.primaryImageUrl != null 
                  ? Image.network(product.primaryImageUrl!, fit: BoxFit.cover) 
                  : Container(color: Colors.grey[300]),
              ),
            ),
            
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'đ${product.price}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),

            // Delete Button
            Consumer<FavoriteProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  onPressed: () {
                    provider.toggleFavorite(product.id);
                  },
                  icon: const Icon(Icons.favorite, color: Colors.red),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}
