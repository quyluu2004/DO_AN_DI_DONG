import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: AppColors.slate),
          SizedBox(height: 16),
          Text(
            'Chào mừng quay lại!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Chọn module bên trái để bắt đầu quản lý.',
            style: TextStyle(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}
