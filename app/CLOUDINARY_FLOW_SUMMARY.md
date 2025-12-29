# Tóm tắt Flow Cloudinary trong Fashion App

## Tổng quan

App sử dụng **Cloudinary** để upload và lưu trữ avatar của user thay vì Firebase Storage. Flow hoạt động như sau:

1. **User chọn ảnh** từ gallery → `ImagePicker`
2. **Upload ảnh lên Cloudinary** → `CloudinaryService`
3. **Lấy secure_url** từ Cloudinary response
4. **Lưu URL vào Firestore** → field `avatarUrl` trong collection `users`
5. **Hiển thị avatar** từ URL → `UserAvatar` component

---

## Flow chi tiết

### 1. Đăng ký tài khoản với Avatar

**File:** `app/lib/ui/auth/avatar_setup_screen.dart`

**Flow:**
```
User đăng ký → Đến màn hình chọn avatar
  ↓
User chọn ảnh từ gallery (_pickImage)
  ↓
Đọc bytes từ file
  ↓
Upload lên Cloudinary (UserService.uploadAvatarBytes)
  ↓
CloudinaryService.uploadAvatar(bytes, userId)
  ↓
POST request đến https://api.cloudinary.com/v1_1/{cloudName}/image/upload
  ↓
Cloudinary trả về secure_url
  ↓
Lưu URL vào RegistrationProvider
  ↓
User click "Hoàn tất" (_complete)
  ↓
Tạo UserModel với avatarUrl
  ↓
Lưu vào Firestore (UserService.createUserProfile)
```

**Các điểm quan trọng:**
- ✅ Upload ngay khi user chọn ảnh (không đợi đến khi hoàn tất)
- ✅ Validate URL trước khi lưu vào Firestore
- ✅ Fallback về default avatar nếu upload thất bại
- ✅ Xử lý lỗi chi tiết với thông báo rõ ràng

---

### 2. Upload Avatar lên Cloudinary

**File:** `app/lib/services/cloudinary_service.dart`

**Cấu hình:**
- Cloud Name: `dufjlirxz`
- Upload Preset: `fashion-app` (Unsigned)
- Endpoint: `https://api.cloudinary.com/v1_1/dufjlirxz/image/upload`

**Flow upload:**
```
1. Tạo MultipartRequest với POST method
2. Thêm file vào request (field name: 'file')
3. Thêm upload_preset vào request fields
4. Thêm public_id = 'avatars/{userId}' (tùy chọn)
5. Thêm folder = 'avatars' (tùy chọn)
6. Gửi request với timeout 90s
7. Đọc response với timeout 30s
8. Parse JSON response
9. Lấy secure_url từ response
10. Trả về secure_url
```

**Xử lý lỗi:**
- Timeout → Thông báo kiểm tra mạng
- Invalid upload preset → Hướng dẫn kiểm tra Cloudinary Dashboard
- Status code != 200 → Hiển thị lỗi chi tiết

---

### 3. Lưu Avatar URL vào Firestore

**File:** `app/lib/services/user_service.dart`

**Hàm chính:**
- `uploadAvatarBytes(bytes)` → Upload lên Cloudinary và trả về URL
- `createUserProfile(user)` → Lưu UserModel vào Firestore (bao gồm avatarUrl)
- `updateAvatar()` → Chọn ảnh, upload, và cập nhật Firestore (dùng sau khi đăng ký)

**Firestore Structure:**
```javascript
users/{userId}
{
  email: string,
  fullName: string,
  phoneNumber: string,
  gender: string,
  birthday: Timestamp,
  avatarUrl: string,  // ← URL từ Cloudinary
  role: string,
  isVerified: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

### 4. Hiển thị Avatar

**File:** `app/lib/ui/components/user_avatar.dart`

**Flow hiển thị:**
```
Kiểm tra avatarUrl có hợp lệ không
  ↓
Nếu có URL hợp lệ (Cloudinary hoặc Firebase Storage):
  → Dùng CachedNetworkImage để load và cache
  → Hiển thị loading indicator khi đang tải
  → Fallback về default avatar nếu lỗi
  ↓
Nếu không có URL hợp lệ:
  → Kiểm tra có placeholderName không
  → Nếu có: Dùng ui-avatars.com để tạo default avatar
  → Nếu không: Hiển thị icon mặc định
```

**URL hợp lệ:**
- Cloudinary: `https://res.cloudinary.com/{cloudName}/image/upload/...`
- Firebase Storage: `https://firebasestorage.googleapis.com/...` (backward compatibility)

---

## Các file liên quan

### Core Services
- ✅ `app/lib/services/cloudinary_service.dart` - Service upload lên Cloudinary
- ✅ `app/lib/services/user_service.dart` - Service quản lý user và avatar

### UI Components
- ✅ `app/lib/ui/auth/avatar_setup_screen.dart` - Màn hình chọn avatar khi đăng ký
- ✅ `app/lib/ui/components/user_avatar.dart` - Component hiển thị avatar (đã hỗ trợ Cloudinary)

### Models
- ✅ `app/lib/models/user_model.dart` - Model user với field `avatarUrl`

### Dependencies (pubspec.yaml)
- ✅ `http: ^1.2.2` - HTTP requests đến Cloudinary API
- ✅ `image_picker: ^1.1.2` - Chọn ảnh từ gallery
- ✅ `cached_network_image: ^3.4.1` - Cache và hiển thị ảnh từ URL
- ⚠️ `firebase_storage: ^13.0.5` - Vẫn còn trong dependencies nhưng không dùng nữa (có thể xóa)

---

## Cấu hình Cloudinary

### Yêu cầu trong Cloudinary Dashboard:

1. **Upload Preset:**
   - Tên: `fashion-app`
   - Mode: **Unsigned** (quan trọng!)
   - Folder: `avatars` (tùy chọn)

2. **Cloud Name:**
   - `dufjlirxz` (đã cấu hình trong code)

### Kiểm tra cấu hình:
- Vào https://cloudinary.com/console
- Settings → Upload presets
- Đảm bảo preset `fashion-app` tồn tại và là **Unsigned**

---

## Xử lý lỗi

### Các lỗi thường gặp:

1. **Timeout khi upload**
   - Nguyên nhân: Mạng chậm hoặc Cloudinary không phản hồi
   - Giải pháp: Kiểm tra mạng, thử lại với ảnh nhỏ hơn

2. **Invalid upload preset**
   - Nguyên nhân: Preset không tồn tại hoặc không phải Unsigned
   - Giải pháp: Kiểm tra Cloudinary Dashboard

3. **Permission denied (Firestore)**
   - Nguyên nhân: Firestore Rules chưa cho phép user ghi
   - Giải pháp: Kiểm tra Firestore Rules

4. **URL không hợp lệ**
   - Nguyên nhân: Cloudinary không trả về secure_url
   - Giải pháp: Kiểm tra response từ Cloudinary

---

## Testing Flow

### Test đăng ký với avatar:

1. ✅ Chọn ảnh từ gallery
2. ✅ Upload lên Cloudinary thành công
3. ✅ Lấy được secure_url
4. ✅ Lưu URL vào Firestore
5. ✅ Hiển thị avatar từ URL

### Test hiển thị avatar:

1. ✅ Hiển thị avatar từ Cloudinary URL
2. ✅ Cache avatar để load nhanh hơn
3. ✅ Fallback về default avatar nếu URL lỗi
4. ✅ Hiển thị placeholder khi không có avatarUrl

---

## Checklist hoàn chỉnh

### Code Implementation
- ✅ CloudinaryService với uploadImage và uploadAvatar
- ✅ UserService với uploadAvatarBytes và createUserProfile
- ✅ AvatarSetupScreen với flow đăng ký
- ✅ UserAvatar component hỗ trợ Cloudinary URL
- ✅ Error handling đầy đủ
- ✅ Loading states và UI feedback

### Configuration
- ✅ Cloud Name: `dufjlirxz`
- ✅ Upload Preset: `fashion-app` (cần kiểm tra trong Dashboard)
- ✅ Dependencies: `http`, `image_picker`, `cached_network_image`

### Documentation
- ✅ CLOUDINARY_FLOW_SUMMARY.md (file này)
- ✅ CLOUDINARY_DEBUG.md (hướng dẫn debug)

---

## Lưu ý quan trọng

1. **Firebase Storage vẫn còn trong dependencies** nhưng không được sử dụng nữa. Có thể xóa để giảm kích thước app.

2. **Backward compatibility:** Code vẫn hỗ trợ Firebase Storage URL để tương thích với dữ liệu cũ (nếu có).

3. **Upload Preset phải là Unsigned** để không cần authentication khi upload.

4. **Timeout:** Upload timeout là 90s, response timeout là 30s để đảm bảo upload ảnh lớn vẫn thành công.

5. **Error messages:** Tất cả error messages đều bằng tiếng Việt và hướng dẫn cụ thể cách khắc phục.

