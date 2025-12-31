
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'order_detail_screen.dart'; // [NEW]
import '../review/write_review_screen.dart'; // [NEW]

class OrderHistoryScreen extends StatefulWidget {
  final int initialIndex;
  const OrderHistoryScreen({super.key, this.initialIndex = 0});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        context.read<OrderProvider>().fetchOrders(user.uid);
      }
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return 'Đơn hàng của tôi';
      case 1: return 'Chờ xác nhận';
      case 2: return 'Đơn hàng đang giao';
      case 3: return 'Lịch sử mua hàng';
      case 4: return 'Đơn đã hủy';
      default: return 'Đơn hàng';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_tabController.index), style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Đã giao'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  'Lỗi: ${orderProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (orderProvider.orders.isEmpty) {
            return const Center(child: Text('Chưa có đơn hàng nào'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(orders: orderProvider.orders),
              _OrderList(orders: orderProvider.orders.where((o) => o.status == OrderStatus.pending).toList()),
              _OrderList(orders: orderProvider.orders.where((o) => o.status == OrderStatus.shipping).toList()),
              _OrderList(orders: orderProvider.orders.where((o) => o.status == OrderStatus.delivered).toList()),
              _OrderList(orders: orderProvider.orders.where((o) => o.status == OrderStatus.cancelled).toList()),
            ],
          );
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đơn hàng #${order.id.substring(order.id.length - 6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const Divider(),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: item.imageUrl.isNotEmpty ? Image.network(item.imageUrl, fit: BoxFit.cover) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('x${item.quantity}', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text('đ ${item.totalPrice}'),
                          ],
                        ),
                        if (order.status == OrderStatus.delivered)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () {
                                   Navigator.push(context, MaterialPageRoute(builder: (_) => WriteReviewScreen(
                                     productId: item.productId,
                                     orderId: order.id,
                                     productName: item.productName,
                                     productImage: item.imageUrl,
                                     variantColor: item.color ?? '',
                                     variantSize: item.size ?? '',
                                   )));
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.charcoal,
                                  side: const BorderSide(color: AppColors.charcoal),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Đánh giá'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${order.items.length} sản phẩm'),
                      Text('Thành tiền: đ ${order.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; break;
      case OrderStatus.shipping: color = Colors.blue; break;
      case OrderStatus.delivered: color = Colors.green; break;
      case OrderStatus.cancelled: color = Colors.red; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
