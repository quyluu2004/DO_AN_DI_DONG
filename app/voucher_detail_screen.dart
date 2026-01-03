import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// [SỬA LỖI 1]: Đổi 'do_an_di_dong' thành 'app' và dùng đường dẫn tương đối
import 'package:app/models/coupon_model.dart';
import 'package:app/models/product_model.dart';
import 'package:app/services/product_service.dart';
import 'package:app/ui/product/product_detail_screen.dart';

class VoucherDetailScreen extends StatelessWidget {
  final CouponModel coupon;

  const VoucherDetailScreen({Key? key, required this.coupon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Đảm bảo CouponType đã có trong coupon_model.dart
    bool isFreeShip = coupon.type == CouponType.freeShip;
    Color themeColor = isFreeShip ? Colors.teal : Colors.orange.shade900;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFreeShip ? "Miễn phí vận chuyển" : "Chi tiết Voucher"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Phần thông tin Voucher
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                border: Border.all(color: themeColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    color: themeColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isFreeShip ? Icons.local_shipping : Icons.shopping_bag, color: Colors.white, size: 30),
                        const SizedBox(height: 5),
                        Text(isFreeShip ? "FREESHIP" : "GIẢM GIÁ", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.code, 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)
                        ),
                        Text("Đơn tối thiểu: ${currencyFormat.format(coupon.minOrderValue)}"),
                        if (isFreeShip)
                          Text("Giảm tối đa: ${currencyFormat.format(coupon.maxShippingDiscount)} ship"),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // 2. Tiêu đề
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
                  Icon(Icons.flash_on, color: Colors.orange),
                  SizedBox(width: 5),
                  Text("DÙNG NGAY VỚI SẢN PHẨM NÀY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                ],
              ),
            ),
          ),

          // 3. Grid sản phẩm
          // [ĐIỀU CHỈNH] Dùng 'Product' và 'ProductService.instance' để khớp với dự án
          FutureBuilder<List<Product>>(
            future: ProductService.instance.getDiscountedProducts(), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text("Chưa có sản phẩm nào.")));
              }
              
              final products = snapshot.data!;
              
              return SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  child: Image.network(
                                    product.primaryImageUrl ?? '', 
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(currencyFormat.format(product.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}