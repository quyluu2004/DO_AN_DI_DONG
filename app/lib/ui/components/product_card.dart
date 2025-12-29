import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'status_badge.dart';

/// Card hiển thị thông tin sản phẩm trong danh sách
/// 
/// Hiển thị đầy đủ thông tin: ảnh, tên, giá, tồn kho, trạng thái, hiệu suất
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onEdit,
    this.onToggleVisibility,
    this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: product.hasViolation
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm
              _ProductImage(imageUrl: product.primaryImageUrl),
              const SizedBox(width: 16),
              
              // Thông tin sản phẩm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên và trạng thái
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F1115),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: product.status, size: StatusBadgeSize.small),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Giá và tồn kho
                    Row(
                      children: [
                        Text(
                          _formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Tồn kho: ${product.stock}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C7077),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Thông tin hiệu suất
                    Row(
                      children: [
                        _PerformanceItem(
                          icon: Icons.visibility_outlined,
                          value: '${product.views}',
                          label: 'Lượt xem',
                        ),
                        const SizedBox(width: 16),
                        _PerformanceItem(
                          icon: Icons.shopping_bag_outlined,
                          value: '${product.sales}',
                          label: 'Đã bán',
                        ),
                        if (product.averageRating != null) ...[
                          const SizedBox(width: 16),
                          _PerformanceItem(
                            icon: Icons.star_outline,
                            value: product.averageRating!.toStringAsFixed(1),
                            label: 'Đánh giá',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menu hành động
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'toggle':
                      onToggleVisibility?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          product.status == ProductStatus.hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.status == ProductStatus.hidden
                              ? 'Hiện sản phẩm'
                              : 'Ẩn sản phẩm',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M đ';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K đ';
    }
    return '$price đ';
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
              ),
            )
          : const Icon(
              Icons.image_outlined,
              color: Colors.grey,
              size: 40,
            ),
    );
  }
}

class _PerformanceItem extends StatelessWidget {
  const _PerformanceItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6C7077)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1115),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C7077),
          ),
        ),
      ],
    );
  }
}

