import 'package:app/models/user_model.dart';
import 'package:app/providers/registration_provider.dart';
import 'package:app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Màn chọn avatar + hoàn tất lưu profile.
class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key});

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  bool _uploading = false;
  bool _saving = false;

  /// Kiểm tra URL có phải là URL hợp lệ (Cloudinary hoặc Firebase Storage) không
  bool _isValidFirebaseStorageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    // Cloudinary URL có dạng: https://res.cloudinary.com/{cloudName}/image/upload/...
    // Firebase Storage URL có dạng: https://firebasestorage.googleapis.com/...
    return url.contains('cloudinary.com') || url.contains('firebasestorage.googleapis.com');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    // Lưu provider reference TRƯỚC khi async operations
    if (!mounted) return;
    final reg = context.read<RegistrationProvider>();
    
    final bytes = await picked.readAsBytes();
    
    // Kiểm tra mounted sau async operation
    if (!mounted) return;
    
    // Set bytes ngay để hiển thị preview (dùng try-catch để tránh lỗi dispose)
    try {
      reg.setAvatarBytes(bytes);
      reg.setAvatarUrl(null);
    } catch (e) {
      // Provider đã bị dispose, không thể set
      if (mounted) {
        debugPrint('AvatarSetupScreen._pickImage: Provider đã dispose, không thể set avatarBytes');
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _uploading = true;
    });

    try {
      // Upload lên Cloudinary và lấy URL
      final url = await UserService.instance.uploadAvatarBytes(bytes);
      
      // Kiểm tra mounted trước khi sử dụng provider
      if (!mounted) return;
      
      // Validate URL trước khi set
      if (!_isValidFirebaseStorageUrl(url)) {
        throw Exception('URL avatar không hợp lệ: $url');
      }
      
      // Set URL vào provider (kiểm tra mounted và dùng try-catch)
      if (mounted) {
        try {
          reg.setAvatarUrl(url);
        } catch (e) {
          // Provider đã bị dispose, nhưng URL đã upload thành công nên không cần xử lý gì
          debugPrint('AvatarSetupScreen._pickImage: Provider đã dispose, nhưng upload thành công');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload avatar thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Reset cả URL và bytes nếu upload thất bại (chỉ khi mounted)
      if (mounted) {
        try {
          reg.setAvatarUrl(null);
          reg.setAvatarBytes(null);
        } catch (_) {
          // Provider đã bị dispose, bỏ qua
        }
      }
      
      if (mounted) {
        final errorMsg = e.toString();
        String displayMsg;
        
        // Xử lý các lỗi cụ thể
        if (errorMsg.contains('TimeoutException') || errorMsg.contains('quá lâu')) {
          displayMsg = 'Upload quá lâu. Vui lòng:\n'
              '1. Kiểm tra kết nối mạng\n'
              '2. Kiểm tra Upload Preset "fashion-app" trong Cloudinary Dashboard\n'
              '3. Thử lại với ảnh nhỏ hơn';
        } else if (errorMsg.contains('Invalid upload preset') || errorMsg.contains('Upload Preset')) {
          displayMsg = 'Upload Preset không hợp lệ.\n'
              'Vui lòng kiểm tra Upload Preset "fashion-app" trong Cloudinary Dashboard.';
        } else if (errorMsg.contains('Storage chưa được cấu hình') || 
            errorMsg.contains('bucket không tồn tại') ||
            errorMsg.contains('404')) {
          displayMsg = 'Cloudinary chưa được cấu hình. Vui lòng kiểm tra Cloudinary Dashboard.';
        } else if (errorMsg.contains('quyền') || errorMsg.contains('unauthorized')) {
          displayMsg = 'Không có quyền upload. Vui lòng kiểm tra Upload Preset.';
        } else {
          displayMsg = 'Upload avatar thất bại: ${errorMsg.length > 150 ? errorMsg.substring(0, 150) + "..." : errorMsg}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _complete({required bool skipAvatar}) async {
    if (_saving || _uploading || !mounted) return;
    
    // Lưu TẤT CẢ các giá trị từ provider vào biến local TRƯỚC khi async
    // để tránh lỗi "used after disposed"
    if (!mounted) return;
    final reg = context.read<RegistrationProvider>();
    
    // Lưu tất cả giá trị cần thiết vào biến local
    final email = reg.email;
    final fullName = reg.fullName;
    final phoneNumber = reg.phoneNumber;
    final gender = reg.gender;
    final birthday = reg.birthday;
    final currentAvatarUrl = reg.avatarUrl;
    final avatarBytes = reg.avatarBytes;

    if (!mounted) return;
    setState(() {
      _saving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Tài khoản chưa sẵn sàng, vui lòng đăng nhập lại.');
      }

      String avatarUrl;
      
      if (skipAvatar) {
        // Nếu skip avatar, dùng default URL
        final encoded =
            Uri.encodeComponent(fullName.isEmpty ? 'User' : fullName);
        avatarUrl =
            'https://ui-avatars.com/api/?name=$encoded&background=random';
      } else {
        // KHÔNG skip avatar - kiểm tra URL hợp lệ TRƯỚC
        final hasValidUrl = _isValidFirebaseStorageUrl(currentAvatarUrl);
        
        if (hasValidUrl) {
          // Nếu đã có URL hợp lệ từ Cloudinary/Firebase Storage, dùng URL đó
          avatarUrl = currentAvatarUrl!;
        } else if (avatarBytes != null) {
          // Nếu có avatarBytes nhưng chưa có URL hợp lệ, upload lại
          if (!mounted) return;
          setState(() {
            _uploading = true;
          });
          
          try {
            avatarUrl = await UserService.instance.uploadAvatarBytes(avatarBytes);
            
            // Kiểm tra mounted trước khi sử dụng provider
            if (!mounted) return;
            
            // Validate URL sau khi upload
            if (!_isValidFirebaseStorageUrl(avatarUrl)) {
              throw Exception('URL avatar không hợp lệ sau khi upload: $avatarUrl');
            }
            
            // Set URL vào provider (chỉ khi mounted)
            if (mounted) {
              try {
                reg.setAvatarUrl(avatarUrl);
              } catch (_) {
                // Provider đã bị dispose, bỏ qua
              }
            }
          } catch (e) {
            // Nếu upload thất bại, hiển thị thông báo chi tiết
            final errorMsg = e.toString();
            if (errorMsg.contains('Storage chưa được cấu hình') || 
                errorMsg.contains('bucket không tồn tại') ||
                errorMsg.contains('404')) {
              throw Exception(
                'Cloudinary chưa được cấu hình.\n\n'
                'Vui lòng:\n'
                '1. Vào Cloudinary Dashboard\n'
                '2. Kiểm tra Upload Preset "fashion-app"\n'
                '3. Đảm bảo Upload Preset là "Unsigned"\n'
                '4. Thử lại sau vài phút'
              );
            }
            throw Exception('Không thể upload avatar: $e');
          } finally {
            if (mounted) {
              setState(() {
                _uploading = false;
              });
            }
          }
        } else {
          // Không có avatar bytes và không skip, dùng default
          final encoded =
              Uri.encodeComponent(fullName.isEmpty ? 'User' : fullName);
          avatarUrl =
              'https://ui-avatars.com/api/?name=$encoded&background=random';
        }
      }

      // Kiểm tra mounted trước khi tiếp tục
      if (!mounted) return;
      
      // Tạo UserModel với avatarUrl đã xác định
      // Sử dụng giá trị đã lưu từ provider thay vì truy cập trực tiếp
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('AvatarSetupScreen._complete: Chuẩn bị lưu vào Firestore');
      debugPrint('AvatarSetupScreen._complete: UID = ${user.uid}');
      debugPrint('AvatarSetupScreen._complete: avatarUrl = $avatarUrl');
      debugPrint('AvatarSetupScreen._complete: avatarUrl hợp lệ? = ${_isValidFirebaseStorageUrl(avatarUrl)}');
      
      // Tạo UserModel từ các giá trị đã lưu (không dùng reg trực tiếp)
      final model = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthday: birthday,
        avatarUrl: avatarUrl,
      );
      debugPrint('AvatarSetupScreen._complete: UserModel.avatarUrl = ${model.avatarUrl}');
      
      // Lưu profile với timeout và xử lý lỗi rõ ràng
      debugPrint('AvatarSetupScreen._complete: Đang gọi createUserProfile...');
      await UserService.instance.createUserProfile(model);
      debugPrint('AvatarSetupScreen._complete: ✅ createUserProfile thành công!');
      
      await UserService.instance.updateFcmToken();
      debugPrint('AvatarSetupScreen._complete: ✅ Hoàn tất tất cả các bước!');
      debugPrint('═══════════════════════════════════════════════════════');

      if (!mounted) return;

      // Đảm bảo đóng màn hình này trước khi hiển thị thông báo
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Hiển thị thông báo sau khi đã navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hoàn tất đăng ký tài khoản.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Hiển thị dialog chi tiết cho các lỗi quan trọng
      final errorMsg = e.toString();
      
      if (errorMsg.contains('Không có quyền ghi vào Firestore') || 
          errorMsg.contains('permission-denied')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi quyền truy cập Firestore'),
            content: Text(
              errorMsg.contains('Không có quyền') 
                ? errorMsg 
                : 'Không có quyền ghi vào Firestore.\n\n'
                  'Vui lòng kiểm tra Firestore Rules trong Firebase Console.\n\n'
                  'Xem hướng dẫn chi tiết trong file FIRESTORE_RULES_FIX.md',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else if (errorMsg.contains('Firestore API chưa được bật')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cần bật Firestore API'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else if (errorMsg.contains('Storage chưa được cấu hình') || 
                 errorMsg.contains('bucket không tồn tại') ||
                 errorMsg.contains('404')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Firebase Storage chưa được cấu hình'),
            content: const Text(
              'Firebase Storage chưa được kích hoạt hoặc chưa được cấu hình đúng.\n\n'
              'Vui lòng:\n'
              '1. Vào Firebase Console → Storage\n'
              '2. Nhấn "Get started" để kích hoạt Storage\n'
              '3. Chọn chế độ "Test mode" hoặc cấu hình Rules phù hợp\n'
              '4. Đợi vài phút rồi thử lại\n\n'
              'Hoặc bạn có thể bỏ qua avatar và dùng avatar mặc định.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lưu hồ sơ thất bại: ${errorMsg.length > 150 ? errorMsg.substring(0, 150) + "..." : errorMsg}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = context.watch<RegistrationProvider>();

    final avatarProvider = reg.avatarBytes != null
        ? MemoryImage(reg.avatarBytes!)
        : (reg.avatarUrl != null
            ? NetworkImage(reg.avatarUrl!) as ImageProvider
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn avatar'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFEDEDED),
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 56,
                              color: Color(0xFF808080),
                            )
                          : null,
                    ),
                    if (_uploading)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn ảnh'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bạn có thể chọn ảnh đại diện ngay bây giờ hoặc bỏ qua và dùng avatar mặc định. '
                'Sau này vẫn có thể thay đổi trong phần hồ sơ.',
                style: TextStyle(fontSize: 13, color: Color(0xFF808080)),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _saving || _uploading ? null : () => _complete(skipAvatar: false),
                  child: (_saving || _uploading)
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Hoàn tất'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed:
                      _saving || _uploading ? null : () => _complete(skipAvatar: true),
                  child: const Text('Bỏ qua, dùng avatar mặc định'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


