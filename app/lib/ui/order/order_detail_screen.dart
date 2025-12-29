import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart'; // [NEW]
import '../../theme/app_theme.dart';
import '../product/product_detail_screen.dart'; // Assuming we might want to nav back to product
import '../../models/product_model.dart'; // For type safety if needed, though we primarily use CartItem

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_getStatusTitle(order.status), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.headset_mic_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Delivery Status & Timeline
            _buildDeliveryStatus(context),

            const SizedBox(height: 10),

            // 2. Address Section
            _buildAddressSection(),

            const SizedBox(height: 10),

            // 3. Product List
            _buildProductList(context),

            const SizedBox(height: 10),

            // 4. Order Information
            _buildOrderInfo(),
            
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(context),
    );
  }

  String _getStatusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Chờ thanh toán / Xử lý';
      case OrderStatus.shipping: return 'Đang giao hàng';
      case OrderStatus.delivered: return 'Đã giao hàng';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }

  Widget _buildDeliveryStatus(BuildContext context) {
    // Estimate delivery: Created + 5 days
    final estimatedDeliveryStart = order.createdAt.add(const Duration(days: 3));
    final estimatedDeliveryEnd = order.createdAt.add(const Duration(days: 6));
    final dateStr = '${DateFormat('dd MMM').format(estimatedDeliveryStart)} - ${DateFormat('dd MMM yyyy').format(estimatedDeliveryEnd)}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light Green
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                   const Icon(Icons.local_shipping_outlined, color: Colors.green),
                   const SizedBox(width: 10),
                   Expanded(
                     child: Text(
                       'Dự kiến giao hàng: $dateStr',
                       style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                     ),
                   ),
                   const Icon(Icons.chevron_right, color: Colors.green),
                ],
              ),
            ),
          
          // Timeline
          _buildTimeline(),
          
          const SizedBox(height: 16),
          
          // Latest Update
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.radio_button_checked, color: Colors.green, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLatestStatusMessage(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy HH:mm').format(order.createdAt), // Mocking latest update time as created time for now
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Theo dõi', style: TextStyle(color: Colors.black, fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }

  String _getLatestStatusMessage() {
    switch (order.status) {
      case OrderStatus.pending: return 'Đơn hàng đã được đặt. Người bán đang chuẩn bị hàng.';
      case OrderStatus.shipping: return 'Đơn hàng đã rời kho và đang trên đường đến bạn.';
      case OrderStatus.delivered: return 'Giao hàng thành công.';
      case OrderStatus.cancelled: return 'Đơn hàng đã bị hủy.';
    }
  }

  Widget _buildTimeline() {
    // Steps: Placed -> Packed -> Shipped -> Delivered
    int currentStep = 0;
    switch (order.status) {
      case OrderStatus.cancelled: currentStep = -1; break;
      case OrderStatus.pending: currentStep = 1; break; // Placed & Packed (Processing)
      case OrderStatus.shipping: currentStep = 2; break;
      case OrderStatus.delivered: currentStep = 3; break;
    }

    return Row(
      children: [
        _buildTimelineStep('Đã đặt', 0, currentStep, isFirst: true),
        _buildTimelineLine(0, currentStep),
        _buildTimelineStep('Đã đóng gói', 1, currentStep),
        _buildTimelineLine(1, currentStep),
        _buildTimelineStep('Đang giao', 2, currentStep),
        _buildTimelineLine(2, currentStep),
        _buildTimelineStep('Đã giao', 3, currentStep, isLast: true),
      ],
    );
  }

  Widget _buildTimelineStep(String label, int stepIndex, int currentStep, {bool isFirst = false, bool isLast = false}) {
    bool isCompleted = stepIndex <= currentStep && currentStep != -1;
    bool isCurrent = stepIndex == currentStep;
    
    Color color = isCompleted ? Colors.green : Colors.grey[300]!;

    return Expanded(
      child: Column(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isCurrent ? Colors.black : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(int stepIndex, int currentStep) {
    bool isCompleted = stepIndex < currentStep && currentStep != -1;
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : Colors.grey[300],
        margin: const EdgeInsets.only(bottom: 14), // Align with icon center roughly
      ),
    );
  }

  Widget _buildAddressSection() {
    final addr = order.shippingAddress;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                    children: [
                      TextSpan(text: '${addr.name} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: addr.phone, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${addr.streetAddress}, ${addr.ward}, ${addr.district}, ${addr.province}',
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),
          ),
          if (order.status == OrderStatus.pending)
             TextButton(onPressed: () {}, child: const Text('Sửa', style: TextStyle(color: Colors.black)))
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Row(
            children: const [
              Icon(Icons.storefront, size: 18),
              SizedBox(width: 8),
              Text('Fashion App Official', style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          
          // Items
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(width: 80, height: 80, color: Colors.grey[200]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Size: ${item.size} / Màu: ${item.color}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(2)),
                            child: const Text('7 ngày đổi trả', style: TextStyle(color: Colors.red, fontSize: 9)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('đ${NumberFormat('#,###').format(item.price)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    // Mocking original price as 1.2x if not available, simply for UI demo as requested
                    Text('đ${NumberFormat('#,###').format(item.price * 1.2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11)),
                    Text('x${item.quantity}', style: const TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          )),

          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('Thành tiền (${order.items.length} sản phẩm):', style: const TextStyle(fontSize: 13)),
               Text('đ${NumberFormat('#,###').format(order.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _buildInfoRow('Mã đơn hàng', order.id.toUpperCase()),
          _buildInfoRow('Thời gian đặt hàng', DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
          _buildInfoRow('Phương thức thanh toán', order.paymentMethod == 'COD' ? 'Thanh toán khi nhận hàng' : order.paymentMethod),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          SelectableText(value, style: const TextStyle(color: Colors.black, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0,-2), blurRadius: 4)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             OutlinedButton(
               onPressed: () {},
               style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), foregroundColor: Colors.black),
               child: const Text('Liên hệ'),
             ),
             const SizedBox(width: 8),
             
             // [NEW] Cancel Button for Pending Orders
             if (order.status == OrderStatus.pending)
               Padding(
                 padding: const EdgeInsets.only(left: 8.0),
                 child: OutlinedButton(
                   onPressed: () => _confirmCancelOrder(context),
                   style: OutlinedButton.styleFrom(
                     side: const BorderSide(color: Colors.red), 
                     foregroundColor: Colors.red
                   ),
                   child: const Text('Hủy đơn hàng'),
                 ),
               ),

             if (order.status == OrderStatus.shipping)
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: const Text('Đã nhận được hàng'),
                ),
             if (order.status == OrderStatus.delivered)
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: const Text('Mua lại'),
                ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                // Assuming provider is available in context. 
                // Since OrderDetailScreen is pushed, it should access inherited providers.
                // We need to import provider package.
                // But this widget is stateless and might need a Builder or check import.
                // Assuming 'provider' is imported at top.
                await context.read<OrderProvider>().cancelOrder(order.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng')));
                  Navigator.pop(context); // Go back to list
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
