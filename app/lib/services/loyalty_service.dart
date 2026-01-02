import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';

class LoyaltyService {
  LoyaltyService._internal();
  static final LoyaltyService instance = LoyaltyService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constants
  static const double POINTS_EARN_RATE = 10000; // 10k VND = 1 Point
  static const double POINT_VALUE = 1000; // 1 Point = 1k VND

  // Tiers
  static const String TIER_MEMBER = 'member';
  static const String TIER_SILVER = 'silver';
  static const String TIER_GOLD = 'gold';
  static const String TIER_DIAMOND = 'diamond';

  // Tier Thresholds
  static const double THRESHOLD_SILVER = 3000000;
  static const double THRESHOLD_GOLD = 10000000;
  static const double THRESHOLD_DIAMOND = 30000000;

  // Check-in Rewards
  static const int DAILY_CHECK_IN_POINTS = 1;
  static const int WEEKLY_STREAK_BONUS = 10;

  Future<void> addPoints(String userId, double amountPaid) async {
    final pointsEarned = (amountPaid / POINTS_EARN_RATE).floor();
    if (pointsEarned <= 0) return;

    try {
      await _db.runTransaction((transaction) async {
        final userDocRef = _db.collection('users').doc(userId);
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) return;

        final currentUser = UserModel.fromDoc(userDoc);
        final newPoints = currentUser.points + pointsEarned;
        final newTotalSpent = currentUser.totalSpent + amountPaid;
        final newTier = _calculateTier(newTotalSpent);

        transaction.update(userDocRef, {
          'points': newPoints,
          'totalSpent': newTotalSpent,
          'tier': newTier,
        });
      });
    } catch (e) {
      debugPrint('Error adding points: $e');
      rethrow;
    }
  }
  
  Future<void> deductPoints(String userId, int pointsToDeduct) async {
      if (pointsToDeduct <= 0) return;

      try {
        await _db.runTransaction((transaction) async {
          final userDocRef = _db.collection('users').doc(userId);
          final userDoc = await transaction.get(userDocRef);

          if (!userDoc.exists) throw Exception('User not found');

          final currentUser = UserModel.fromDoc(userDoc);
          if (currentUser.points < pointsToDeduct) {
             throw Exception('Insufficient points');
          }

          final newPoints = currentUser.points - pointsToDeduct;

          transaction.update(userDocRef, {
            'points': newPoints,
          });
        });
      } catch (e) {
        debugPrint('Error deducting points: $e');
        rethrow;
      }
    }

  String _calculateTier(double totalSpent) {
    if (totalSpent > THRESHOLD_DIAMOND) return TIER_DIAMOND;
    if (totalSpent > THRESHOLD_GOLD) return TIER_GOLD;
    if (totalSpent > THRESHOLD_SILVER) return TIER_SILVER;
    return TIER_MEMBER;
  }
  
  TierInfo getTierInfo(String tier) {
    switch (tier) {
      case TIER_SILVER:
        return TierInfo(
          name: 'Silver', 
          color: Colors.grey, 
          icon: Icons.star_half,
          nextThreshold: THRESHOLD_GOLD,
          benefits: ['Tích điểm 1.2x', 'Mã Freeship hàng tháng']
        );
      case TIER_GOLD:
        return TierInfo(
          name: 'Gold', 
          color: Colors.amber, 
          icon: Icons.star,
          nextThreshold: THRESHOLD_DIAMOND,
          benefits: ['Tích điểm 1.5x', 'Hỗ trợ ưu tiên', 'Quà sinh nhật']
        );
      case TIER_DIAMOND:
        return TierInfo(
          name: 'Diamond', 
          color: Colors.cyan, 
          icon: Icons.diamond,
          nextThreshold: double.infinity,
          benefits: ['Tích điểm 2.0x', 'Đặc quyền VIP', 'Hoàn tiền 1%']
        );
      default:
        return TierInfo(
          name: 'Member', 
          color: Colors.brown, 
          icon: Icons.person,
          nextThreshold: THRESHOLD_SILVER,
          benefits: ['Tích điểm cơ bản']
        );
    }
  }

  Future<CheckInResult> processDailyCheckIn() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDocRef = _db.collection('users').doc(user.uid);
    
    return await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userDocRef);
      if (!userDoc.exists) throw Exception('User data not found');

      final userData = UserModel.fromDoc(userDoc);
      final lastDate = userData.lastCheckInDate;
      final today = DateTime.now();
      
      // Check if already checked in today
      if (lastDate != null && 
          lastDate.year == today.year && 
          lastDate.month == today.month && 
          lastDate.day == today.day) {
        return CheckInResult(success: false, message: 'Bạn đã điểm danh hôm nay rồi!');
      }

      int newStreak = 1;
      int pointsToAdd = DAILY_CHECK_IN_POINTS;

      // Check if consecutive
      if (lastDate != null) {
        final yesterday = today.subtract(const Duration(days: 1));
        final isConsecutive = lastDate.year == yesterday.year && 
                              lastDate.month == yesterday.month && 
                              lastDate.day == yesterday.day;
        
        if (isConsecutive) {
          newStreak = userData.checkInStreak + 1;
           // Bonus on 7th day
          if (newStreak % 7 == 0) {
            pointsToAdd += WEEKLY_STREAK_BONUS;
          }
        }
      }

      transaction.update(userDocRef, {
        'lastCheckInDate': Timestamp.fromDate(today),
        'checkInStreak': newStreak,
        'points': userData.points + pointsToAdd,
      });

      return CheckInResult(
        success: true, 
        message: 'Điểm danh thành công! +$pointsToAdd điểm', 
        pointsAdded: pointsToAdd,
        newStreak: newStreak
      );
    });
  }

  double getPointValue(int points) {
    return points * POINT_VALUE;
  }

  int getMaxRedeemablePoints(double orderTotal, int userPoints) {
    // Max redeemable: 50% of order value
    final maxDiscount = orderTotal * 0.5;
    final maxPointsByValue = (maxDiscount / POINT_VALUE).floor();
    
    return userPoints < maxPointsByValue ? userPoints : maxPointsByValue;
  }
}

class TierInfo {
  final String name;
  final Color color;
  final IconData icon;
  final double nextThreshold;
  final List<String> benefits;

  TierInfo({
    required this.name,
    required this.color,
    required this.icon,
    required this.nextThreshold,
    required this.benefits,
  });
}

class CheckInResult {
  final bool success;
  final String message;
  final int pointsAdded;
  final int newStreak;

  CheckInResult({
    required this.success, 
    required this.message, 
    this.pointsAdded = 0, 
    this.newStreak = 0
  });
}
