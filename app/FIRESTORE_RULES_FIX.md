# Sửa lỗi Permission Denied trong Firestore

## Lỗi bạn đang gặp

```
FirebaseException: permission-denied - Missing or insufficient permissions.
```

## Nguyên nhân

Firestore Rules chưa cho phép user ghi vào collection `users` khi đăng ký tài khoản.

## Cách sửa NGAY LẬP TỨC

### Bước 1: Vào Firebase Console

1. Truy cập: https://console.firebase.google.com/
2. Chọn project của bạn (fashion-app)
3. Vào **Firestore Database** → **Rules** (tab ở trên cùng)

### Bước 2: Copy Rules này và Paste vào

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Collection users: chỉ user đó mới đọc/ghi được profile của mình
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Collection shops: chỉ shop owner mới đọc/ghi được shop của mình
    match /shops/{shopId} {
      allow read, write: if request.auth != null && request.auth.uid == shopId;
      
      // Subcollection products: chỉ shop owner mới thêm/sửa/xóa sản phẩm
      match /products/{productId} {
        allow read, write: if request.auth != null && request.auth.uid == shopId;
      }
    }
    
    // Tất cả các collection khác: chỉ user đã đăng nhập mới đọc được
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Không cho phép ghi vào collection khác
    }
  }
}
```

### Bước 3: Publish Rules

1. Click nút **"Publish"** (màu xanh, góc trên bên phải)
2. Đợi vài giây để Rules được áp dụng

### Bước 4: Test lại

1. Quay lại app
2. Thử đăng ký lại với avatar
3. Kiểm tra Firestore Database → Data → users → {your-uid}
4. Phải thấy document với avatarUrl từ Cloudinary

## Giải thích Rules

### Rule cho collection `users`:

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**Ý nghĩa:**
- `request.auth != null` → User phải đã đăng nhập
- `request.auth.uid == userId` → UID của user đăng nhập phải khớp với `userId` trong document path
- `allow read, write` → Cho phép đọc và ghi

**Ví dụ:**
- User có UID = `abc123` đăng nhập
- User có thể đọc/ghi document `/users/abc123`
- User KHÔNG thể đọc/ghi document `/users/xyz789`

## Kiểm tra Rules đã đúng chưa

### Cách 1: Test trong Firebase Console

1. Vào **Firestore Database** → **Rules**
2. Click **"Rules Playground"** (góc trên bên phải)
3. Chọn:
   - **Location**: `users/{userId}` → Nhập `users/abc123` (thay bằng UID của bạn)
   - **Authenticated**: ✅ Yes
   - **User ID**: Nhập UID của bạn (ví dụ: `iQ8yAFQBUFWWfEoF1EkLI0burO63`)
   - **Operation**: `write` hoặc `create`
4. Click **"Run"**
5. Nếu hiện ✅ thì Rules đúng, nếu ❌ thì cần sửa lại

### Cách 2: Kiểm tra trong app

Sau khi sửa Rules và Publish:
1. Đăng ký lại với avatar
2. Vào Firebase Console → Firestore Database → Data
3. Xem collection `users`
4. Phải thấy document với UID của bạn
5. Document phải có field `avatarUrl` với URL từ Cloudinary

## Lưu ý quan trọng

1. **Sau khi sửa Rules, PHẢI click "Publish"** mới có hiệu lực
2. Rules có thể mất vài giây để áp dụng (thường là ngay lập tức)
3. Đảm bảo user đã **authenticated** (đăng nhập) trước khi ghi vào Firestore
4. UID trong document path (`/users/{userId}`) phải **khớp** với UID của user đang đăng nhập

## Nếu vẫn lỗi sau khi sửa Rules

1. **Kiểm tra lại Rules đã Publish chưa**
   - Vào Rules → Xem Rules hiện tại có giống Rules ở trên không
   - Nếu khác, copy lại và Publish

2. **Kiểm tra user đã authenticated chưa**
   - Xem log trong console: `UserService.createUserProfile: Is Authenticated = true/false`
   - Nếu `false`, nghĩa là user chưa đăng nhập

3. **Kiểm tra UID có khớp không**
   - Xem log: `UserService.createUserProfile: UID = ...`
   - Xem log: `UserService.createUserProfile: Current Auth UID = ...`
   - Hai UID phải giống nhau

4. **Clear cache và thử lại**
   - Đăng xuất và đăng nhập lại
   - Hoặc xóa app và cài lại

## Liên kết hữu ích

- Firebase Console: https://console.firebase.google.com/
- Firestore Rules Documentation: https://firebase.google.com/docs/firestore/security/get-started
- Rules Playground: https://console.firebase.google.com/project/_/firestore/rules

