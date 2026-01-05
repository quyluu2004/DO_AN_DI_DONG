import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';

class VoucherSection extends StatelessWidget {
  const VoucherSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CouponModel>>(
      // TODO: Add a specific stream for "Voucher List" if needed, 
      // for now filtering from all coupons or adding a new query in Service.
      // Assuming we want to show active, non-flash-sale coupons or a specific collection.
      // Based on request "List Voucher uu dai", let's fetch valid coupons.
      stream: CouponService.instance.getCouponsStream(), 
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        // Filter: Active, Not Expired, Not Flash Sale (since Flash Sale is separate), Public (allowedUserIds empty)
        final vouchers = snapshot.data!.where((c) {
          final now = DateTime.now();
          return c.isActive && 
                 c.endDate.isAfter(now) && 
                 !c.isFlashSale && 
                 c.allowedUserIds.isEmpty;
        }).toList();

        if (vouchers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'ƯU ĐÃI - ONLY ONLINE', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
              ),
            ),
            SizedBox(
              height: 140, // Adjust height as needed
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: vouchers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => VoucherCard(coupon: vouchers[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class VoucherCard extends StatelessWidget {
  final CouponModel coupon;

  const VoucherCard({super.key, required this.coupon});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã voucher'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          // Yellow Strip
          Container(
            width: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFD4AF37), // Amber/Gold
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                     children: [
                       Expanded(
                         child: Text(
                           coupon.title.toUpperCase(),
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Text(
                     coupon.description.isNotEmpty ? coupon.description : 'Ưu đãi đặc biệt',
                     style: TextStyle(color: Colors.grey[400], fontSize: 12),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Mã: ${coupon.code}',
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                           ),
                           const SizedBox(height: 2),
                           Text(
                             'HSD: ${DateFormat('dd/MM/yyyy').format(coupon.endDate)}',
                             style: TextStyle(color: Colors.grey[500], fontSize: 10),
                           ),
                         ],
                       ),
                       InkWell(
                         onTap: () => _copyToClipboard(context),
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.black,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.grey[700]!),
                           ),
                           child: const Text(
                             'Sao chép mã',
                             style: TextStyle(color: Colors.grey, fontSize: 10),
                           ),
                         ),
                       )
                     ],
                   )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
