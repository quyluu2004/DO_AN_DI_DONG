import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';

class CouponListModal extends StatelessWidget {
  const CouponListModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kho Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CouponModel>>(
              stream: CouponService.instance.getCouponsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final coupons = (snapshot.data ?? []).where((c) {
                  return c.isActive && DateTime.now().isBefore(c.endDate);
                }).toList();

                if (coupons.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text('Hiện chưa có mã giảm giá nào', style: TextStyle(color: Colors.grey)),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return _buildCouponTicket(context, coupon);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponTicket(BuildContext context, CouponModel coupon) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: coupon.discountType == 'percent' ? Colors.orange.shade50 : Colors.blue.shade50,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    coupon.discountType == 'percent' ? Icons.percent : Icons.attach_money,
                    color: coupon.discountType == 'percent' ? Colors.orange : Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coupon.discountType == 'percent' ? 'GIẢM %' : 'GIẢM TIỀN',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      color: coupon.discountType == 'percent' ? Colors.orange : Colors.blue
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.code, // Sử dụng code làm tiêu đề
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đơn tối thiểu: ${currencyFormat.format(coupon.minOrderValue)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade100)
                      ),
                      child: Text(
                        'Hạn: ${dateFormat.format(coupon.endDate)}',
                        style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: coupon.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã sao chép mã: ${coupon.code}'))
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Dùng'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}