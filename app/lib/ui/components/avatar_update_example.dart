import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'user_avatar.dart';

/// Ví dụ về cách sử dụng hàm updateAvatar và widget UserAvatar.
/// 
/// File này chỉ để tham khảo, không được import vào app chính.
class AvatarUpdateExample extends StatefulWidget {
  const AvatarUpdateExample({super.key});

  @override
  State<AvatarUpdateExample> createState() => _AvatarUpdateExampleState();
}

class _AvatarUpdateExampleState extends State<AvatarUpdateExample> {
  bool _isLoading = false;
  String? _currentAvatarUrl;
  String? _errorMessage;

  /// Ví dụ 1: Sử dụng hàm updateAvatar với callbacks
  Future<void> _updateAvatarWithCallbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = await UserService.instance.updateAvatar(
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        },
      );

      if (url != null) {
        setState(() {
          _currentAvatarUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật avatar thành công!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Ví dụ 2: Sử dụng hàm updateAvatar với try-catch thông thường
  Future<void> _updateAvatarWithTryCatch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = await UserService.instance.updateAvatar();
      
      if (url != null) {
        setState(() {
          _currentAvatarUrl = url;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật avatar thành công!'),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví dụ cập nhật Avatar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Hiển thị avatar với widget UserAvatar
            Stack(
              alignment: Alignment.center,
              children: [
                UserAvatar(
                  avatarUrl: _currentAvatarUrl,
                  size: 120,
                  placeholderName: 'User Name',
                  onTap: _updateAvatarWithCallbacks,
                ),
                if (_isLoading)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateAvatarWithCallbacks,
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh từ Gallery'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _updateAvatarWithTryCatch,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Cập nhật Avatar (Try-Catch)'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Hướng dẫn sử dụng:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Widget UserAvatar tự động hiển thị:\n'
              '   - Ảnh từ avatarUrl nếu có (với cache)\n'
              '   - Placeholder từ tên nếu không có avatarUrl\n'
              '   - Icon mặc định nếu không có gì cả\n\n'
              '2. Hàm updateAvatar() xử lý:\n'
              '   - Chọn ảnh từ gallery\n'
              '   - Upload lên Firebase Storage\n'
              '   - Cập nhật Firestore\n'
              '   - Callbacks để hiển thị loading/error',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

