# Hướng dẫn Debug Cloudinary Upload

## Lỗi Timeout khi upload avatar

Nếu bạn gặp lỗi timeout, hãy kiểm tra các điểm sau:

### 1. Kiểm tra Upload Preset trong Cloudinary Dashboard

1. Vào https://cloudinary.com/console
2. Đăng nhập vào tài khoản của bạn
3. Vào **Settings** → **Upload** → **Upload presets**
4. Tìm preset có tên **`fashion-app`**
5. Kiểm tra:
   - ✅ Preset đã được tạo chưa?
   - ✅ **Signing Mode** phải là **"Unsigned"** (quan trọng!)
   - ✅ Tên preset chính xác: `fashion-app` (case-sensitive)

### 2. Kiểm tra Cloud Name

1. Vào Cloudinary Dashboard
2. Kiểm tra **Cloud Name** ở góc trên bên phải
3. Đảm bảo Cloud Name trong code là: `dufjlirxz`

### 3. Kiểm tra kết nối mạng

- Đảm bảo thiết bị/emulator có kết nối internet
- Thử mở trình duyệt và truy cập: https://api.cloudinary.com
- Kiểm tra firewall/antivirus có chặn không

### 4. Kiểm tra kích thước file

- File quá lớn có thể gây timeout
- Code đã tự động giới hạn: maxWidth/maxHeight = 1024px
- Nếu vẫn lỗi, thử với ảnh nhỏ hơn

### 5. Xem log chi tiết

Khi chạy app, mở terminal và tìm các dòng log:
- `CloudinaryService: Bắt đầu upload ảnh`
- `CloudinaryService: Cloud Name = ...`
- `CloudinaryService: Upload Preset = ...`
- `CloudinaryService: File size = ...`

Nếu thấy timeout, log sẽ hiển thị:
- `❌ CloudinaryService: Timeout sau Xs`

## Các lỗi phổ biến

### Lỗi "Invalid upload preset"
- **Nguyên nhân**: Upload Preset chưa được tạo hoặc tên sai
- **Giải pháp**: 
  1. Vào Cloudinary Dashboard → Settings → Upload presets
  2. Tạo preset mới tên `fashion-app`
  3. Chọn "Unsigned" mode
  4. Save và thử lại

### Lỗi Timeout
- **Nguyên nhân**: 
  - Kết nối mạng chậm
  - File quá lớn
  - Upload Preset chưa được cấu hình đúng
- **Giải pháp**:
  1. Kiểm tra kết nối mạng
  2. Thử với ảnh nhỏ hơn
  3. Kiểm tra Upload Preset trong Dashboard

### Lỗi 401 Unauthorized
- **Nguyên nhân**: Upload Preset không phải "Unsigned"
- **Giải pháp**: Đổi Signing Mode thành "Unsigned" trong Dashboard

## Test Upload Preset

Bạn có thể test Upload Preset bằng cách:

1. Vào Cloudinary Dashboard → Media Library
2. Nhấn **Upload** → **Advanced**
3. Chọn **Upload Preset**: `fashion-app`
4. Upload một ảnh test
5. Nếu thành công → Preset đã đúng
6. Nếu lỗi → Cần sửa lại Preset

## Kiểm tra code

File cấu hình: `app/lib/services/cloudinary_service.dart`

```dart
// Dòng 21-24
static const String cloudName = 'dufjlirxz';
static const String uploadPreset = 'fashion-app';
```

Đảm bảo các giá trị này khớp với Cloudinary Dashboard của bạn.

## Liên kết hữu ích

- [Cloudinary Dashboard](https://cloudinary.com/console)
- [Upload Presets Documentation](https://cloudinary.com/documentation/upload_presets)
- [Unsigned Upload Guide](https://cloudinary.com/documentation/upload_images#unsigned_upload)

