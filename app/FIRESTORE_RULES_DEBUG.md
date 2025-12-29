# Hướng dẫn Debug Firestore Rules

## Lỗi bạn đang gặp

Nếu bạn đã bật Firestore Database nhưng vẫn gặp lỗi khi lưu dữ liệu, có thể do **Firestore Rules** chưa được cấu hình đúng.

## Cách kiểm tra và sửa

### Bước 1: Kiểm tra Firestore Rules hiện tại

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Firestore Database** → **Rules** (tab ở trên cùng)
4. Xem Rules hiện tại của bạn

### Bước 2: Cấu hình Rules đúng

Rules của bạn cần cho phép user **ghi vào collection `users` với document ID = UID của chính họ**.

**Rules đúng cho collection `users`:**

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

### Bước 3: Copy Rules vào Firebase Console

1. Copy toàn bộ Rules ở trên
2. Paste vào Firebase Console → Firestore Database → Rules
3. Click **"Publish"** để lưu
4. Đợi vài giây để Rules được áp dụng

### Bước 4: Kiểm tra lại

1. Đảm bảo bạn đã **đăng nhập** (authenticated) trước khi đăng ký
2. Thử đăng ký lại trong app
3. Kiểm tra console log để xem lỗi cụ thể

## Debug trong app

App sẽ hiển thị log chi tiết trong console:

```
UserService.createUserProfile: Current Auth UID = ...
UserService.createUserProfile: Is Authenticated = true/false
UserService.createUserProfile: ❌ FirebaseException: Code: permission-denied
```

### Các lỗi thường gặp:

1. **`permission-denied`**
   - Nguyên nhân: Firestore Rules chưa cho phép user ghi
   - Giải pháp: Cập nhật Rules như ở Bước 2

2. **`UID không khớp`**
   - Nguyên nhân: UID trong UserModel khác với UID của user đang đăng nhập
   - Giải pháp: Kiểm tra code đăng ký, đảm bảo dùng đúng UID từ `FirebaseAuth.currentUser`

3. **`Chưa đăng nhập`**
   - Nguyên nhân: User chưa được authenticate trước khi gọi `createUserProfile`
   - Giải pháp: Đảm bảo user đã đăng ký/đăng nhập thành công trước khi lưu profile

## Kiểm tra nhanh trong Firebase Console

1. Vào **Firestore Database** → **Data**
2. Xem có collection `users` chưa
3. Nếu có, xem có document nào với UID của bạn chưa
4. Nếu chưa có, nghĩa là Rules chưa cho phép ghi

## Test Rules trong Firebase Console

Firebase Console có công cụ **Rules Playground** để test Rules:

1. Vào **Firestore Database** → **Rules**
2. Click **"Rules Playground"** (góc trên bên phải)
3. Chọn:
   - **Location**: `users/{userId}` (ví dụ: `users/abc123`)
   - **Authenticated**: Yes
   - **User ID**: UID của bạn
   - **Operation**: `write` hoặc `create`
4. Click **"Run"** để test
5. Nếu hiện ✅ thì Rules đúng, nếu ❌ thì cần sửa Rules

## Lưu ý quan trọng

- Sau khi sửa Rules, phải click **"Publish"** mới có hiệu lực
- Rules có thể mất vài giây để áp dụng
- Đảm bảo user đã **authenticated** (đăng nhập) trước khi ghi vào Firestore
- UID trong document phải **khớp** với UID của user đang đăng nhập

