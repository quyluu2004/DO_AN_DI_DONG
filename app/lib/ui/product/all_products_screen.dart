import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'package:app/l10n/arb/app_localizations.dart';
import '../components/grid_product_card.dart';

class AllProductsScreen extends StatelessWidget {
  final String? category;

  const AllProductsScreen({super.key, this.category});

  String _getTitle(BuildContext context) {
    if (category == null || category == 'Xem tất cả' || category == AppLocalizations.of(context)!.seeAll) {
      return AppLocalizations.of(context)!.allProducts ?? 'Tất cả sản phẩm';
    }
    return category!;
  }

  @override
  Widget build(BuildContext context) {
    // Map display category to database value if needed
    // 'Nam' -> 'Men', 'Nữ' -> 'Women', 'Kid' -> 'Kids', 'Phụ kiện' -> 'Accessories'
    String? apiCategory;
    if (category != null) {
      final lower = category!.toLowerCase();
      if (lower.contains('nam') || lower.contains('men')) apiCategory = 'Men';
      else if (lower.contains('nữ') || lower.contains('women')) apiCategory = 'Women';
      else if (lower.contains('kid')) apiCategory = 'Kids';
      else if (lower.contains('phụ kiện') || lower.contains('accessories')) apiCategory = 'Accessories';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(context)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService.instance.getProductsStream(
          status: ProductStatus.active,
          category: apiCategory, // Pass the mapped category
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: SelectableText('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
             return const Center(child: Text('Không có sản phẩm nào'));
          }
          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.70, 
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GridProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}
