import 'package:flutter/material.dart';
import '../../models/coupon_model.dart';
import 'package:intl/intl.dart';
import 'voucher_detail_screen.dart';

class GiftReceivedDialog extends StatelessWidget {
  final List<CouponModel> coupons;

  const GiftReceivedDialog({Key? key, required this.coupons}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              "QUÀ TẶNG CẢM ƠN!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              "Cảm ơn bạn đã mua hàng. Bạn nhận được ${coupons.length} voucher:",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            // Danh sách coupon
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  String discountText = coupon.discountType == 'percent'
                      ? "Giảm ${coupon.discountValue.toStringAsFixed(0)}%"
                      : "Giảm ${currencyFormat.format(coupon.discountValue)}";

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mã: ${coupon.code}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(discountText, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng popup
                // Nếu có quà, chuyển đến trang chi tiết của quà đầu tiên
                if (coupons.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VoucherDetailScreen(coupon: coupons.first)),
                  );
                }
              },
              child: const Text("DÙNG NGAY"),
            )
          ],
        ),
      ),
    );
  }
}