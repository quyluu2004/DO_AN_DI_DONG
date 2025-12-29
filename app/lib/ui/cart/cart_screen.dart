import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_model.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../checkout/checkout_screen.dart'; // Added import
import '../try_on/virtual_try_on_screen.dart'; // [NEW]

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background like reference
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Consumer<CartProvider>(
          builder: (_, cart, __) => Text(
            'Giỏ hàng (${cart.itemCount})',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Giỏ hàng trống'),

                ],
              ),
            );
          }

          return Column(
            children: [
              // Free Shipping Banner
              Container(
                width: double.infinity,
                color: const Color(0xFFE8F5E9), // Light green
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Miễn phí vận chuyển cho mọi đơn hàng',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, color: Colors.green, size: 18),
                  ],
                ),
              ),
              
              // Cart Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: cartProvider.cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cartProvider.cart.items[index];
                    return _CartItemWidget(item: item);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final total = cartProvider.totalAmount;
          final isAllSelected = cartProvider.isAllSelected;
          final selectedCount = cartProvider.selectedItemCount;

          return Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Standard Checkout Bar
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // All Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isAllSelected,
                                activeColor: Colors.black,
                                shape: const CircleBorder(),
                                onChanged: (val) {
                                  cartProvider.toggleAll(val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Tất cả', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Total & Checkout
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Text('Tổng: ', style: TextStyle(fontSize: 14)),
                                Text(
                                  currencyFormat.format(total),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: selectedCount > 0 ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text('Mua hàng ($selectedCount)'),
                        ),
                      ],
                    ),
                  ),
                  
                  // [NEW] Try On Bar
                  if (selectedCount > 0)
                    Container(
                      color: Colors.black12,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.checkroom, size: 20),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                                final selectedItems = cartProvider.cart.items.where((i) => i.isSelected).toList();
                                final tryOnProducts = selectedItems.map((item) => Product(
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
                                )).toList();

                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => VirtualTryOnScreen(initialProducts: tryOnProducts))
                                );
                            },
                            child: const Text('Thử đồ các món đã chọn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;

  const _CartItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.read<CartProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name (Mock)
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: item.isSelected,
                  activeColor: Colors.black,
                  shape: const CircleBorder(),
                  onChanged: (val) {
                    cartProvider.toggleSelection(item.productId, item.size, item.color);
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.storefront, size: 18),
              const SizedBox(width: 4),
              const Text('Fashion Official Store', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          
          // Product Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox for Item (Aligned with image)
              const SizedBox(width: 32), // Indent to match header checkbox
              
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.imageUrl,
                  width: 90,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90, 
                    height: 110, 
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    
                    // Variant Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.color != null) ...[
                            Text(item.color!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 4),
                          ],
                          if (item.size != null) ...[
                            Text('/ ${item.size!}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                          const Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                         Text(
                          currencyFormat.format(item.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Quantity Control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         // Delete Icon
                         InkWell(
                           onTap: () {
                             // Confirm delete?
                             cartProvider.removeFromCart(item.productId, item.size, item.color);
                           },
                           child: const Padding(
                             padding: EdgeInsets.all(4.0),
                             child: Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                           ),
                         ),

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove, 
                                onTap: () => cartProvider.updateQuantity(item.productId, item.size, item.color, item.quantity - 1),
                              ),
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Text('${item.quantity}', style: const TextStyle(fontSize: 13)),
                              ),
                              _QtyButton(
                                icon: Icons.add, 
                                onTap: () => cartProvider.updateQuantity(item.productId, item.size, item.color, item.quantity + 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(icon, size: 14),
      ),
    );
  }
}
