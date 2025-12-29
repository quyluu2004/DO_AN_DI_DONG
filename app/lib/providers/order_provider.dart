
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error; // [NEW]

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error; // [NEW]

  Future<void> createOrder(OrderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('orders').doc(order.id).set(order.toMap());
      // Local update
      _orders.insert(0, order);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _orders = snapshot.docs.map((doc) => OrderModel.fromDoc(doc)).toList();
    } catch (e) {
      print(e);
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
      });

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        // Create new object with updated status to ensure immutability/UI update
        final oldOrder = _orders[index];
        _orders[index] = OrderModel(
          id: oldOrder.id,
          userId: oldOrder.userId,
          items: oldOrder.items,
          totalAmount: oldOrder.totalAmount,
          shippingAddress: oldOrder.shippingAddress,
          status: OrderStatus.cancelled, // Updated
          paymentMethod: oldOrder.paymentMethod,
          createdAt: oldOrder.createdAt,
          discountAmount: oldOrder.discountAmount,
          couponCode: oldOrder.couponCode,
        );
      }
    } catch (e) {
      print(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
