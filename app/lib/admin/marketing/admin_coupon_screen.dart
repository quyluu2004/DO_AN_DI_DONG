import 'package:flutter/material.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import 'package:intl/intl.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Mã giảm giá'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCouponDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: CouponService.instance.getCouponsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final coupons = snapshot.data ?? [];
          if (coupons.isEmpty) {
            return const Center(child: Text('Chưa có mã giảm giá nào'));
          }

          return ListView.builder(
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giảm: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(coupon.discountAmount)}'),
                      Text('Đơn tối thiểu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(coupon.minOrderValue)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: coupon.isActive,
                        onChanged: (val) {
                          CouponService.instance.updateCouponStatus(coupon.id, val);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, coupon.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa mã giảm giá?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              CouponService.instance.deleteCoupon(id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCouponDialog(BuildContext context) {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final minOrderController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm mã giảm giá mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Mã giảm giá (VD: SALE50)'),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(labelText: 'Số tiền giảm (VNĐ)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: minOrderController,
              decoration: const InputDecoration(labelText: 'Đơn tối thiểu (VNĐ)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim().toUpperCase();
              final discount = double.tryParse(discountController.text) ?? 0;
              final minOrder = double.tryParse(minOrderController.text) ?? 0;

              if (code.isNotEmpty && discount > 0) {
                final newCoupon = CouponModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  code: code,
                  discountAmount: discount,
                  minOrderValue: minOrder,
                  createdAt: DateTime.now(),
                );
                CouponService.instance.createCoupon(newCoupon);
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
