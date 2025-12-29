import 'package:flutter/material.dart';
import '../../models/product_model.dart';

/// Badge hiển thị trạng thái sản phẩm với màu sắc phù hợp
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.size = StatusBadgeSize.medium,
  });

  final ProductStatus status;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StatusBadgeSize.small ? 8 : 12,
        vertical: size == StatusBadgeSize.small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: size == StatusBadgeSize.small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return _StatusConfig(
          label: 'Đang bán',
          backgroundColor: const Color(0xFF10B981), // Xanh lá
          textColor: Colors.white,
        );
      case ProductStatus.hidden:
        return _StatusConfig(
          label: 'Tạm ẩn',
          backgroundColor: const Color(0xFFF59E0B), // Vàng
          textColor: Colors.white,
        );
      case ProductStatus.outOfStock:
        return _StatusConfig(
          label: 'Hết hàng',
          backgroundColor: const Color(0xFF6B7280), // Xám
          textColor: Colors.white,
        );
      case ProductStatus.violation:
        return _StatusConfig(
          label: 'Vi phạm',
          backgroundColor: const Color(0xFFEF4444), // Đỏ
          textColor: Colors.white,
        );
      case ProductStatus.draft:
        return _StatusConfig(
          label: 'Nháp',
          backgroundColor: const Color(0xFFE5E7EB), // Xám nhạt
          textColor: const Color(0xFF6B7280),
        );
    }
  }
}

enum StatusBadgeSize {
  small,
  medium,
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

