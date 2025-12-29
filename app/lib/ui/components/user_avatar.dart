import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget tái sử dụng để hiển thị avatar người dùng.
/// 
/// Tự động xử lý:
/// - Hiển thị ảnh từ avatarUrl nếu có (với cache)
/// - Hiển thị placeholder/icon mặc định nếu avatarUrl null/empty
/// - Bo tròn ảnh (Circle Avatar)
/// - Loading state khi đang tải ảnh
/// - Error handling khi không load được ảnh
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 80,
    this.placeholderIcon,
    this.placeholderName,
    this.onTap,
  });

  /// URL của avatar từ Firestore (field "avatarUrl").
  /// Nếu null hoặc empty, sẽ hiển thị placeholder.
  final String? avatarUrl;

  /// Kích thước của avatar (width và height).
  final double size;

  /// Icon mặc định khi không có avatarUrl.
  /// Mặc định là Icons.person_outline.
  final IconData? placeholderIcon;

  /// Tên người dùng để tạo default avatar từ ui-avatars.com.
  /// Nếu không cung cấp, sẽ chỉ hiển thị icon.
  final String? placeholderName;

  /// Callback khi người dùng tap vào avatar.
  final VoidCallback? onTap;

  /// Kiểm tra URL có phải là URL hợp lệ (Cloudinary hoặc Firebase Storage) không.
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    // Cloudinary URL có dạng: https://res.cloudinary.com/{cloudName}/image/upload/...
    // Firebase Storage URL có dạng: https://firebasestorage.googleapis.com/...
    return url.contains('cloudinary.com') || url.contains('firebasestorage.googleapis.com');
  }

  /// Tạo URL mặc định từ tên người dùng (ui-avatars.com).
  String _getDefaultAvatarUrl() {
    if (placeholderName != null && placeholderName!.isNotEmpty) {
      final encoded = Uri.encodeComponent(placeholderName!);
      return 'https://ui-avatars.com/api/?name=$encoded&background=random&size=${size.toInt()}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isValidUrl = _isValidImageUrl(avatarUrl);
    final imageUrl = isValidUrl ? avatarUrl! : _getDefaultAvatarUrl();
    final hasDefaultUrl = imageUrl.isNotEmpty;

    Widget avatarWidget;

    if (isValidUrl) {
      // Có avatarUrl hợp lệ từ Cloudinary hoặc Firebase Storage - hiển thị với cache
      avatarWidget = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: const Color(0xFFEDEDED),
            child: Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF808080)),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // Nếu load lỗi, fallback về default avatar hoặc icon
            if (hasDefaultUrl) {
              return ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _getDefaultAvatarUrl(),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                ),
              );
            }
            return _buildPlaceholder();
          },
        ),
      );
    } else if (hasDefaultUrl) {
      // Không có avatarUrl hợp lệ nhưng có placeholderName - dùng ui-avatars.com
      avatarWidget = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    } else {
      // Không có gì cả - hiển thị icon mặc định
      avatarWidget = _buildPlaceholder();
    }

    // Wrap với GestureDetector nếu có onTap
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  /// Widget placeholder khi không có avatar.
  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEDEDED),
        shape: BoxShape.circle,
      ),
      child: Icon(
        placeholderIcon ?? Icons.person_outline,
        size: size * 0.5,
        color: const Color(0xFF808080),
      ),
    );
  }
}

