# Hướng dẫn cấu hình Firebase Storage

## Vấn đề: Lỗi upload avatar (404 - Object does not exist)

Lỗi này xảy ra khi Firebase Storage chưa được kích hoạt hoặc chưa được cấu hình đúng.

## Các bước khắc phục:

### 1. Kích hoạt Firebase Storage

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Storage** ở menu bên trái
4. Nếu chưa có Storage, nhấn **"Get started"**
5. Chọn chế độ:
   - **Test mode** (cho development - cho phép đọc/ghi trong 30 ngày)
   - **Production mode** (cần cấu hình Rules)

### 2. Cấu hình Storage Rules

Vào **Storage** → **Rules** và cập nhật như sau:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Cho phép user upload avatar của chính họ
    match /avatars/{userId}.jpg {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    // Hoặc nếu muốn cho phép tất cả user đã đăng nhập upload vào thư mục avatars
    match /avatars/{allPaths=**} {
      allow write: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

**Lưu ý:** 
- Sau khi cập nhật Rules, nhấn **"Publish"**
- Đợi vài phút để Rules được áp dụng

### 3. Kiểm tra Storage Bucket

1. Vào **Storage** → **Files**
2. Đảm bảo bucket đã được tạo
3. Thử upload một file test để kiểm tra

### 4. Kiểm tra quyền truy cập

Đảm bảo trong Firebase Console:
- **Authentication** đã được bật
- User đã đăng nhập thành công
- UID của user hợp lệ

## Cấu hình cho Production

Khi deploy lên production, nên sử dụng Rules chặt chẽ hơn:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Chỉ cho phép user upload avatar của chính họ
    match /avatars/{userId}.jpg {
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // Giới hạn 5MB
                   && request.resource.contentType.matches('image/.*');
      allow read: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### Lỗi 404 - Object does not exist
- **Nguyên nhân:** Storage bucket chưa được tạo hoặc chưa được kích hoạt
- **Giải pháp:** Làm theo bước 1 ở trên

### Lỗi Permission denied
- **Nguyên nhân:** Storage Rules không cho phép upload
- **Giải pháp:** Cập nhật Rules như bước 2 ở trên

### Lỗi Timeout
- **Nguyên nhân:** Kết nối mạng chậm hoặc file quá lớn
- **Giải pháp:** 
  - Kiểm tra kết nối mạng
  - Giảm kích thước ảnh (code đã tự động giới hạn maxWidth/maxHeight = 1024px)

## Kiểm tra trong code

Code đã tự động:
- Giới hạn kích thước ảnh: maxWidth/maxHeight = 1024px
- Giảm chất lượng: imageQuality = 85%
- Timeout: 60 giây cho upload, 15 giây cho lấy URL
- Xử lý lỗi chi tiết với thông báo rõ ràng

## Liên kết hữu ích

- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)
- [Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Flutter Firebase Storage](https://firebase.flutter.dev/docs/storage/overview)

