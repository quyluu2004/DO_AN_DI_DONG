import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/loyalty_service.dart';
import 'package:intl/intl.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành viên thân thiết'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final userData = UserModel.fromDoc(snapshot.data as DocumentSnapshot<Map<String, dynamic>>);
          final tierInfo = LoyaltyService.instance.getTierInfo(userData.tier);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Membership Card
                _buildMembershipCard(userData, tierInfo),
                const SizedBox(height: 24),

                // 2. Check-in Section
                _buildCheckInSection(context, userData),
                const SizedBox(height: 24),

                // 3. Tier Benefits
                const Text('Quyền lợi hiện tại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildBenefitsList(tierInfo),
                
                const SizedBox(height: 24),
                // 4. Next Tier Progress
                if (tierInfo.nextThreshold != double.infinity)
                   _buildNextTierProgress(userData, tierInfo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembershipCard(UserModel user, TierInfo tierInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierInfo.color.withOpacity(0.8), tierInfo.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: tierInfo.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tierInfo.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(tierInfo.icon, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 30),
          const Text('ĐIỂM TÍCH LŨY', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            '${NumberFormat('#,###').format(user.points)} điểm', 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInSection(BuildContext context, UserModel user) {
    // Basic streak visualization
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Điểm danh nhận quà', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${user.checkInStreak} ngày liên tiếp', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _handleCheckIn(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Điểm danh'),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Streak circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = index + 1;
              // Simple logic: if streak % 7 >= day, it's checked (roughly)
              // Better logic handled by tracking lastCheckIn date vs today etc.
              // For simplicity: Show 1-7. If checkInStreak % 7 >= day -> active.
              // Note: This is simplified visualization.
              final currentCycleDay = user.checkInStreak % 7; 
              // Correction: if streak is 7, mod is 0. 
              final displayDay = currentCycleDay == 0 && user.checkInStreak > 0 ? 7 : currentCycleDay;
              
              final isActive = day <= displayDay;
              final isBonus = day == 7;

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orange : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: isBonus ? Border.all(color: Colors.orange, width: 2) : null,
                    ),
                    child: isActive 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('+$day', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text('Ngày $day', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildBenefitsList(TierInfo tierInfo) {
    return Column(
      children: tierInfo.benefits.map((benefit) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(benefit),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNextTierProgress(UserModel user, TierInfo tierInfo) {
    final remaining = tierInfo.nextThreshold - user.totalSpent;
    final progress = user.totalSpent / tierInfo.nextThreshold;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thăng hạng tiếp theo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          color: tierInfo.color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          'Mua thêm ${NumberFormat('#,###').format(remaining)}đ để lên hạng kế tiếp',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    try {
      final result = await LoyaltyService.instance.processDailyCheckIn();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}
