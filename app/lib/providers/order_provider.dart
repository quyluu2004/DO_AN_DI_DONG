
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/loyalty_service.dart';

class OrderProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> createOrder(OrderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      String? validationError;

      await _db.runTransaction((transaction) async {
        // 1. Check Stock for ALL items first
        for (final item in order.items) {
          final productRef = _db.collection('products').doc(item.productId);
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            validationError = "Sản phẩm '${item.productName}' không tồn tại!";
            return; // Abort
          }

          final currentStock = (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
          if (currentStock < item.quantity) {
             validationError = "Sản phẩm '${item.productName}' không đủ hàng (Chỉ còn $currentStock, bạn mua ${item.quantity})";
             return; // Abort
          }
        }

        // 2. If all checks pass (and no validation error), Perform Updates
        if (validationError == null) {
          final orderRef = _db.collection('orders').doc(order.id);
          transaction.set(orderRef, order.toMap());

          for (final item in order.items) {
            final productRef = _db.collection('products').doc(item.productId);
            transaction.update(productRef, {
              'stock': FieldValue.increment(-item.quantity),
              'sales': FieldValue.increment(item.quantity),
            });
          }
        }
      });
      
      // Check if validation failed inside transaction
      if (validationError != null) {
        throw Exception(validationError);
      }
      
      // Deduct points if used (Outside transaction as it might involve different logic/collection, 
      // but ideally should be inside if points are critical. Keeping outside for now as per previous logic)
      if (order.pointsUsed > 0) {
        try {
          await LoyaltyService.instance.deductPoints(order.userId, order.pointsUsed);
        } catch (e) {
          print("Error deducting points: $e");
        }
      }

      // Local update
      _orders.insert(0, order);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', ''); // Clean error message
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<OrderModel>> getMyOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
            return snapshot.docs.map((doc) => OrderModel.fromDoc(doc)).toList();
        });
  }

  // Deprecated: Use stream instead for real-time updates
  Future<void> fetchOrders(String userId) async {
      // Just a wrapper or initial fetch if needed
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
        final oldOrder = _orders[index];
        _orders[index] = OrderModel(
          id: oldOrder.id,
          userId: oldOrder.userId,
          items: oldOrder.items,
          totalAmount: oldOrder.totalAmount,
          shippingAddress: oldOrder.shippingAddress,
          status: OrderStatus.cancelled,
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

  Future<void> completeOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Update status in Firestore
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.delivered.name,
      });

      // 2. Fetch order data to ensure we have details for points (crucial for Admin app)
      OrderModel? orderData;
      final index = _orders.indexWhere((o) => o.id == orderId);
      
      if (index != -1) {
        // Use local data if available
        final oldOrder = _orders[index];
        orderData = oldOrder;
        
        // Update local state
        _orders[index] = OrderModel(
          id: oldOrder.id,
          userId: oldOrder.userId,
          items: oldOrder.items,
          totalAmount: oldOrder.totalAmount,
          shippingAddress: oldOrder.shippingAddress,
          status: OrderStatus.delivered,
          paymentMethod: oldOrder.paymentMethod,
          createdAt: oldOrder.createdAt,
          discountAmount: oldOrder.discountAmount,
          couponCode: oldOrder.couponCode,
        );
      } else {
        // Fetch from Firestore if not in local list (e.g. Admin app)
        final doc = await _db.collection('orders').doc(orderId).get();
        if (doc.exists) {
           orderData = OrderModel.fromDoc(doc);
        }
      }

      // 3. Add points if we have order data
      if (orderData != null) {
        await LoyaltyService.instance.addPoints(orderData.userId, orderData.totalAmount);
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
