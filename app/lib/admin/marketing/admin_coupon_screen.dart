// app/lib/admin/marketing/admin_coupon_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import 'add_coupon_screen.dart'; // [QUAN TRỌNG] Import màn hình thêm mới
import 'package:intl/intl.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  
  // Hàm format tiền tệ
  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  // Hàm hiển thị text giảm giá thông minh
  String getDiscountDisplay(CouponModel coupon) {
    if (coupon.discountType == 'percent') {
      // Nếu là phần trăm
      String text = 'Giảm: ${coupon.discountValue.toStringAsFixed(0)}%';
      if (coupon.maxDiscount != null) {
        text += ' (Tối đa ${formatCurrency(coupon.maxDiscount!)})';
      }
      return text;
    } else {
      // Nếu là số tiền cố định
      return 'Giảm: ${formatCurrency(coupon.discountValue)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Mã giảm giá'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // [SỬA LỖI 1] Chuyển sang màn hình AddCouponScreen xịn thay vì popup
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCouponScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: CouponService.instance.getCouponsStream(), // Giả sử service bạn có hàm này trả về Stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          
          final coupons = snapshot.data ?? [];
          
          if (coupons.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.discount_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Chưa có mã giảm giá nào'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              
              // Kiểm tra trạng thái hết hạn để hiển thị màu khác
              bool isExpired = DateTime.now().isAfter(coupon.endDate);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isExpired ? Colors.grey.shade200 : null, // Xám nếu hết hạn
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        coupon.code, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isExpired ? Colors.grey : Colors.blue
                        )
                      ),
                      if (isExpired)
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: Text("HẾT HẠN", style: TextStyle(color: Colors.white, fontSize: 10)),
                        )
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // [SỬA LỖI 3] Hiển thị đúng % hoặc tiền
                      Text(
                        getDiscountDisplay(coupon),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Text('Đơn tối thiểu: ${formatCurrency(coupon.minOrderValue)}'),
                      Text(
                        'Hạn: ${DateFormat('dd/MM/yyyy').format(coupon.endDate)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (coupon.targetCategories.isNotEmpty)
                        Text(
                          'Áp dụng: ${coupon.targetCategories.join(", ")}',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.indigo),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: coupon.isActive,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          // Gọi service update status
                          // CouponService.instance.updateCouponStatus(coupon.id, val);
                          // Code mẫu nếu service chưa có hàm update status riêng:
                          FirebaseFirestore.instance
                              .collection('coupons')
                              .doc(coupon.id)
                              .update({'isActive': val});
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
            onPressed: () async {
               // Gọi đúng hàm delete trong service
               // await CouponService.instance.deleteCoupon(id);
               // Code mẫu trực tiếp:
               await FirebaseFirestore.instance.collection('coupons').doc(id).delete();
               Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}