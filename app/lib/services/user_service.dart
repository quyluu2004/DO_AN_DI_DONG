import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'cloudinary_service.dart';

class UserService {
  UserService._internal();

  static final UserService instance = UserService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// Upload avatar (bytes) lên Cloudinary và trả về secure_url.
  /// 
  /// Sử dụng CloudinaryService để upload ảnh lên Cloudinary.
  /// Ảnh sẽ được lưu tại: avatars/{uid} trong Cloudinary.
  /// 
  /// [bytes] - Dữ liệu ảnh dạng Uint8List
  /// 
  /// Trả về secure_url của ảnh đã upload trên Cloudinary.
  Future<String> uploadAvatarBytes(Uint8List bytes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Chưa đăng nhập, không thể upload avatar');
    }

    try {
      // Sử dụng CloudinaryService để upload avatar lên Cloudinary
      final imageUrl = await CloudinaryService.instance.uploadAvatar(
        bytes: bytes,
        userId: uid,
      );

      return imageUrl;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      // Re-throw để caller có thể xử lý
      rethrow;
    }
  }

  /// Tạo hoặc cập nhật profile user trong collection `users`.
  Future<void> createUserProfile(UserModel user) async {
    if (kDebugMode) {
      debugPrint('UserService.createUserProfile: Bắt đầu lưu profile');
      debugPrint('UserService.createUserProfile: UID = ${user.uid}');
      debugPrint('UserService.createUserProfile: Current Auth UID = ${_auth.currentUser?.uid}');
      debugPrint('UserService.createUserProfile: Is Authenticated = ${_auth.currentUser != null}');
      debugPrint('UserService.createUserProfile: avatarUrl = ${user.avatarUrl}');
      debugPrint('UserService.createUserProfile: Data to save = ${user.toMap()}');
    }
    
    // Kiểm tra user có đang authenticated không
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Chưa đăng nhập, không thể lưu profile');
    }
    
    if (currentUser.uid != user.uid) {
      throw StateError('UID không khớp: current=${currentUser.uid}, model=${user.uid}');
    }
    
    try {
      final result = await _usersCol
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Lưu hồ sơ quá lâu, vui lòng kiểm tra kết nối mạng.');
            },
          );
      
      if (kDebugMode) {
        debugPrint('UserService.createUserProfile: ✅ Lưu thành công!');
        // Verify lại sau khi lưu
        final verifyDoc = await _usersCol.doc(user.uid).get();
        if (verifyDoc.exists) {
          final data = verifyDoc.data();
          debugPrint('UserService.createUserProfile: Verified - avatarUrl trong Firestore = ${data?['avatarUrl']}');
        } else {
          debugPrint('UserService.createUserProfile: ⚠️ WARNING - Document không tồn tại sau khi lưu!');
        }
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('UserService.createUserProfile: ❌ FirebaseException:');
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - StackTrace: ${e.stackTrace}');
      }
      
      // Phân biệt các loại lỗi
      if (e.code == 'permission-denied') {
        // Lỗi permission-denied thường do Firestore Rules
        throw Exception(
          'Không có quyền ghi vào Firestore.\n\n'
          'Nguyên nhân có thể:\n'
          '1. Firestore Rules chưa cho phép user ghi vào collection "users"\n'
          '2. User chưa được authenticate đúng cách\n\n'
          'Vui lòng kiểm tra Firestore Rules:\n'
          'match /users/{userId} {\n'
          '  allow read, write: if request.auth != null && request.auth.uid == userId;\n'
          '}',
        );
      }
      
      if (e.message?.contains('API has not been used') == true || 
          e.message?.contains('not enabled') == true) {
        throw Exception(
          'Firestore API chưa được bật. Vui lòng vào Firebase Console → Enable Cloud Firestore API.\n'
          'Hoặc đợi vài phút nếu vừa enable.',
        );
      }
      
      throw Exception('Lỗi Firestore (${e.code}): ${e.message ?? "Không xác định"}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserService.createUserProfile: ❌ Exception: $e');
      }
      rethrow;
    }
  }

  /// Cập nhật FCM token cho user hiện tại.
  Future<void> updateFcmToken() async {
    // Tạm thời bỏ trống vì chưa cấu hình firebase_messaging
    // Nếu sau này thêm firebase_messaging, có thể cài lại logic lấy token ở đây.
    return;
  }

  /// Lấy thông tin user profile từ Firestore.
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream thông tin user profile từ Firestore (real-time).
  Stream<UserModel?> currentUserProfileStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }

    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  /// Cập nhật avatar người dùng: chọn ảnh từ gallery, upload lên Cloudinary và cập nhật Firestore.
  /// 
  /// Flow hoạt động:
  /// 1. User chọn ảnh từ gallery (ImagePicker)
  /// 2. Upload ảnh lên Cloudinary (CloudinaryService)
  /// 3. Lấy secure_url từ Cloudinary
  /// 4. Lưu secure_url vào Firestore field 'avatarUrl'
  /// 
  /// [onLoading] callback được gọi khi đang upload (true) hoặc hoàn thành (false).
  /// [onError] callback được gọi khi có lỗi xảy ra.
  /// 
  /// Trả về secure_url của avatar đã upload trên Cloudinary, hoặc null nếu người dùng hủy chọn ảnh.
  Future<String?> updateAvatar({
    void Function(bool isLoading)? onLoading,
    void Function(String error)? onError,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      final errorMsg = 'Chưa đăng nhập, không thể cập nhật avatar';
      onError?.call(errorMsg);
      throw StateError(errorMsg);
    }

    try {
      // Bước 1: Chọn ảnh từ gallery
      onLoading?.call(true);
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Giảm chất lượng để giảm kích thước file
        maxWidth: 1024, // Giới hạn kích thước để tối ưu
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        // Người dùng hủy chọn ảnh
        onLoading?.call(false);
        return null;
      }

      // Bước 2: Đọc bytes từ file
      final bytes = await pickedFile.readAsBytes();

      // Bước 3: Upload lên Cloudinary
      final downloadUrl = await uploadAvatarBytes(bytes);

      // Bước 4: Cập nhật avatarUrl vào Firestore
      await _usersCol.doc(uid).update({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Cập nhật avatar quá lâu, vui lòng kiểm tra kết nối mạng.');
        },
      );

      onLoading?.call(false);
      return downloadUrl;
    } on FirebaseException catch (e) {
      final errorMsg = 'Lỗi Firebase: ${e.message ?? e.code}';
      onError?.call(errorMsg);
      onLoading?.call(false);
      throw Exception(errorMsg);
    } on TimeoutException catch (e) {
      final errorMsg = e.toString();
      onError?.call(errorMsg);
      onLoading?.call(false);
      rethrow;
    } catch (e) {
      final errorMsg = 'Lỗi không xác định: $e';
      onError?.call(errorMsg);
      onLoading?.call(false);
      throw Exception(errorMsg);
    }
  }

  /// Cập nhật avatarUrl trong Firestore (dùng khi đã có URL sẵn).
  Future<void> updateAvatarUrl(String avatarUrl) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Chưa đăng nhập, không thể cập nhật avatar');
    }

    try {
      await _usersCol.doc(uid).update({
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Cập nhật avatar quá lâu, vui lòng kiểm tra kết nối mạng.');
        },
      );
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}


