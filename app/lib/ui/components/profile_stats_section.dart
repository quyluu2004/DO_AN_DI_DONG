import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import 'coupon_list_modal.dart';

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: StreamBuilder<List<CouponModel>>(
              stream: CouponService.instance.getCouponsStream(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData) {
                  count = snapshot.data!.where((c) => c.isActive && DateTime.now().isBefore(c.endDate)).length;
                }

                return _buildStatItem(
                  context,
                  count.toString(), 
                  "Mã giảm giá", 
                  icon: Icons.confirmation_number_outlined,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const CouponListModal(),
                    );
                  }
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: UserService.instance.currentUserProfileStream(),
              builder: (context, snapshot) {
                 final points = snapshot.data?.points ?? 0;
                 return _buildStatItem(context, "$points", "Điểm", icon: Icons.star_border, onTap: () {});
              }
            ),
          ),
          Expanded(
            child: _buildStatItem(context, "", "Ví", icon: Icons.account_balance_wallet_outlined, isIconOnly: true, onTap: () {}),
          ),
          Expanded(
            child: _buildStatItem(context, "", "Quà tặng", icon: Icons.card_giftcard, isIconOnly: true, onTap: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, {
    required IconData icon, 
    bool isIconOnly = false,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIconOnly)
            Icon(icon, size: 24, color: Colors.black87)
          else
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}