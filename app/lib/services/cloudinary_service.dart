import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service để xử lý upload ảnh lên Cloudinary.
/// 
/// Cloudinary là một dịch vụ quản lý và tối ưu hóa media (ảnh, video).
/// Service này cung cấp các hàm để upload ảnh và nhận về URL công khai.
class CloudinaryService {
  CloudinaryService._internal();

  static final CloudinaryService instance = CloudinaryService._internal();

  // ============================================
  // CẤU HÌNH CLOUDINARY
  // ============================================
  /// Cloud Name từ .env
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  
  /// Upload Preset từ .env
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  
  /// API Endpoint để upload ảnh lên Cloudinary
  static String get uploadUrl => 
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Upload ảnh (bytes) lên Cloudinary và trả về URL công khai.
  /// 
  /// [bytes] - Dữ liệu ảnh dạng Uint8List
  /// [publicId] - Tên file trong Cloudinary (tùy chọn, nếu null sẽ tự động generate)
  /// [folder] - Thư mục lưu trữ trong Cloudinary (tùy chọn)
  /// 
  /// Trả về [String] là secure_url của ảnh đã upload.
  /// Throw [Exception] nếu upload thất bại.
  Future<String> uploadImage({
    required Uint8List bytes,
    String? publicId,
    String? folder,
  }) async {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('CloudinaryService: Bắt đầu upload ảnh');
      debugPrint('CloudinaryService: Cloud Name = $cloudName');
      debugPrint('CloudinaryService: Upload Preset = $uploadPreset');
      debugPrint('CloudinaryService: Upload URL = $uploadUrl');
      debugPrint('CloudinaryService: File size = ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(2)} KB)');
      debugPrint('CloudinaryService: Public ID = $publicId');
      debugPrint('CloudinaryService: Folder = $folder');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    try {
      // Bước 1: Tạo multipart request để upload ảnh
      final uri = Uri.parse(uploadUrl);
      if (kDebugMode) {
        debugPrint('CloudinaryService: Tạo request đến $uri');
      }
      
      final request = http.MultipartRequest('POST', uri);

      // Bước 2: Thêm file ảnh vào request
      // Cloudinary yêu cầu field name là 'file'
      final filename = publicId != null ? '$publicId.jpg' : 'image.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      if (kDebugMode) {
        debugPrint('CloudinaryService: Đã thêm file vào request: $filename');
      }

      // Bước 3: Thêm các tham số cấu hình
      request.fields['upload_preset'] = uploadPreset;
      
      // Nếu có publicId, đặt tên file trong Cloudinary
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }
      
      // Nếu có folder, tổ chức vào thư mục đó
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      if (kDebugMode) {
        debugPrint('CloudinaryService: Request fields: ${request.fields}');
        debugPrint('CloudinaryService: Đang gửi request...');
      }

      // Bước 4: Gửi request với timeout
      final stopwatch = Stopwatch()..start();
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90), // Tăng timeout lên 90s
        onTimeout: () {
          stopwatch.stop();
          if (kDebugMode) {
            debugPrint('❌ CloudinaryService: Timeout sau ${stopwatch.elapsed.inSeconds}s');
          }
          throw TimeoutException(
            'Upload ảnh quá lâu (${stopwatch.elapsed.inSeconds}s), vui lòng kiểm tra kết nối mạng hoặc upload preset.',
          );
        },
      );

      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('✅ CloudinaryService: Request đã được gửi thành công sau ${stopwatch.elapsed.inSeconds}s');
        debugPrint('CloudinaryService: Status code = ${streamedResponse.statusCode}');
      }

      // Bước 5: Đọc response từ Cloudinary
      if (kDebugMode) {
        debugPrint('CloudinaryService: Đang đọc response...');
      }
      
      final responseStopwatch = Stopwatch()..start();
      final response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 30), // Tăng timeout đọc response
        onTimeout: () {
          responseStopwatch.stop();
          if (kDebugMode) {
            debugPrint('❌ CloudinaryService: Timeout đọc response sau ${responseStopwatch.elapsed.inSeconds}s');
          }
          throw TimeoutException('Nhận phản hồi từ Cloudinary quá lâu.');
        },
      );

      responseStopwatch.stop();
      if (kDebugMode) {
        debugPrint('✅ CloudinaryService: Đã nhận response sau ${responseStopwatch.elapsed.inSeconds}s');
        debugPrint('CloudinaryService: Response status = ${response.statusCode}');
        debugPrint('CloudinaryService: Response body length = ${response.body.length}');
      }

      // Bước 6: Kiểm tra status code
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('❌ CloudinaryService: Upload thất bại với status ${response.statusCode}');
          debugPrint('CloudinaryService: Response body = ${response.body}');
        }
        
        // Parse error message từ response
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorBody['error']?['message'] ?? response.body;
          
          // Kiểm tra các lỗi phổ biến
          if (errorMessage.toString().contains('Invalid upload preset')) {
            throw Exception(
              'Upload Preset không hợp lệ. Vui lòng kiểm tra:\n'
              '1. Upload Preset "$uploadPreset" đã được tạo trong Cloudinary Dashboard\n'
              '2. Upload Preset đã được set là "Unsigned"\n'
              '3. Tên preset chính xác (case-sensitive)',
            );
          }
          
          throw Exception(
            'Cloudinary upload thất bại (${response.statusCode}): $errorMessage',
          );
        } catch (e) {
          if (e.toString().contains('Upload Preset')) {
            rethrow;
          }
          throw Exception(
            'Cloudinary upload thất bại (${response.statusCode}): ${response.body}',
          );
        }
      }

      // Bước 7: Parse response để lấy URL
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      // Cloudinary trả về 'secure_url' (HTTPS) hoặc 'url' (HTTP)
      // Ưu tiên dùng secure_url để bảo mật hơn
      final imageUrl = responseData['secure_url'] as String? ?? 
                      responseData['url'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ CloudinaryService: Response không chứa secure_url hoặc url');
          debugPrint('CloudinaryService: Response data = $responseData');
        }
        throw Exception('Cloudinary không trả về URL hợp lệ.');
      }

      if (kDebugMode) {
        debugPrint('✅ CloudinaryService: Upload thành công!');
        debugPrint('CloudinaryService: Image URL = $imageUrl');
        debugPrint('═══════════════════════════════════════════════════════');
      }

      return imageUrl;
    } on TimeoutException {
      // Re-throw TimeoutException để caller có thể xử lý riêng
      rethrow;
    } on FormatException catch (e) {
      // Lỗi parse JSON
      if (kDebugMode) {
        debugPrint('❌ Lỗi parse response từ Cloudinary: $e');
      }
      throw Exception('Lỗi parse response từ Cloudinary: $e');
    } catch (e) {
      // Các lỗi khác
      if (kDebugMode) {
        debugPrint('❌ Lỗi upload ảnh lên Cloudinary: $e');
      }
      
      // Nếu đã là TimeoutException thì rethrow
      if (e is TimeoutException) {
        rethrow;
      }
      
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  /// Upload avatar của user lên Cloudinary.
  /// 
  /// [bytes] - Dữ liệu ảnh avatar
  /// [userId] - ID của user để đặt tên file
  /// 
  /// Trả về secure_url của avatar đã upload.
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String userId,
  }) async {
    return uploadImage(
      bytes: bytes,
      publicId: 'avatars/$userId',
      folder: 'avatars',
    );
  }
}

