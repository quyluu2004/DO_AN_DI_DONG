import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/favorite_provider.dart';
import '../product/product_detail_screen.dart';

class GridProductCard extends StatelessWidget {
  final Product product;
  const GridProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.primaryImageUrl != null 
                    ? Image.network(product.primaryImageUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, child) {
                        final isFavorite = favoriteProvider.isFavorite(product.id);
                        return GestureDetector(
                          onTap: () => favoriteProvider.toggleFavorite(product.id),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                          ),
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    product.name, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontSize: 13, color: Colors.black87)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}đ', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD61C4E))
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        '${product.averageRating?.toStringAsFixed(1) ?? "5.0"}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        'Đã bán ${product.sales > 0 ? product.sales : 0}', 
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
