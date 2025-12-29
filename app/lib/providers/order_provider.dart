
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> createOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection('orders').doc(order.id).set(order.toMap());
      // Local update
      _orders.insert(0, order);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders(String userId) async {
    _isLoading = true;
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
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
