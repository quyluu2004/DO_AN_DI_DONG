import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return const _AdminOrderList(tabIndex: 0);
  }
}

class _AdminOrderList extends StatelessWidget {
  final int tabIndex;
  const _AdminOrderList({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    // Filter stream based on tab
    // 0 = All, 1..N = OrderStatus[i-1]
    
    // db removed

    // We need to fetch data. Let's use Firestore directly for simplicity in this file
    // modifying the top imports to include cloud_firestore
    return StreamBuilder<List<OrderModel>>(
      stream: _getOrdersStream(tabIndex),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('Không có đơn hàng nào'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        );
      },
    );
  }
  
  // This needs to be static or moved to a provider/service, but keeping here for cohesion
   Stream<List<OrderModel>> _getOrdersStream(int index) {
     final collection = FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true);
     
     if (index == 0) {
       return collection.snapshots().map((s) => s.docs.map((d) => OrderModel.fromDoc(d)).toList());
     }
     
     final status = OrderStatus.values[index - 1];
     return collection
         .where('status', isEqualTo: status.name)
         .snapshots()
         .map((s) => s.docs.map((d) => OrderModel.fromDoc(d)).toList());
   }
}

// Workaround for imports inside the class logic (anti-pattern but useful for single file write if I missed imports)
// I will ensure imports are correct at the top.
// import 'package:cloud_firestore/cloud_firestore.dart' as import_firestore;

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text('Đơn #${order.id.substring(order.id.length - 6)} - ${currencyFormat.format(order.totalAmount)}'),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}\n${order.status.label}',
          style: TextStyle(color: _getStatusColor(order.status)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.productName} (${item.size ?? '-'}, ${item.color ?? '-'})')),
                    Text(currencyFormat.format(item.totalPrice)),
                  ],
                )),
                const Divider(),
                Text('Khách hàng: ${order.shippingAddress.name} - ${order.shippingAddress.phone}'),
                Text('Địa chỉ: ${order.shippingAddress.fullAddress}'),
                if (order.couponCode != null)
                   Text('Mã giảm giá: ${order.couponCode} (-${currencyFormat.format(order.discountAmount)})', style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == OrderStatus.pending)
                      ElevatedButton(
                        onPressed: () => _updateStatus(context, order.id, OrderStatus.shipping),
                        child: const Text('Xác nhận & Giao'),
                      ),
                    if (order.status == OrderStatus.shipping)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _updateStatus(context, order.id, OrderStatus.delivered),
                        child: const Text('Hoàn thành'),
                      ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Future<void> _updateStatus(BuildContext context, String orderId, OrderStatus status) async {
    try {
       if (status == OrderStatus.delivered) {
         // Use the provider method which handles status update AND points
         await Provider.of<OrderProvider>(context, listen: false).completeOrder(orderId);
       } else {
         // For other statuses, just update firestore directly or add specific methods in provider
         await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status.name});
       }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.shipping: return Colors.blue;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }
}
