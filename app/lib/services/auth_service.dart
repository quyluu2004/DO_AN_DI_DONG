import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service dùng để làm việc với Firebase Authentication.
/// 
/// Bạn chỉ cần gọi `AuthService.instance` ở bất kỳ đâu trong app.
class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Dùng API google_sign_in 6.x với constructor mặc định
  // Trên web, clientId sẽ được lấy từ meta tag trong index.html
  // Nếu meta tag không có, có thể truyền clientId trực tiếp:
  // GoogleSignIn(clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com')
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// User hiện tại (có thể null nếu chưa đăng nhập).
  User? get currentUser => _auth.currentUser;

  /// Lắng nghe trạng thái đăng nhập (login / logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký tài khoản với email & password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException.fromFirebase(e);
    } catch (e) {
      throw AuthServiceException('Lỗi không xác định: $e');
    }
  }

  /// Đăng nhập với email & password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException.fromFirebase(e);
    } catch (e) {
      throw AuthServiceException('Lỗi không xác định: $e');
    }
  }

  /// Đăng xuất.
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Đăng nhập / đăng ký bằng Google (Gmail).
  Future<UserCredential> signInWithGoogle() async {
    try {
      // B1: hiển thị màn hình chọn tài khoản Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthServiceException('Đã huỷ đăng nhập Google.');
      }

      // B2: lấy token xác thực
      final googleAuth = await googleUser.authentication;

      // B3: tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // B4: đăng nhập Firebase (tự tạo account nếu chưa có)
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException.fromFirebase(e);
    } catch (e) {
      // Xử lý lỗi People API chưa được bật
      final errorStr = e.toString();
      if (errorStr.contains('People API') || errorStr.contains('people.googleapis.com')) {
        throw AuthServiceException(
          'People API chưa được bật. Vui lòng:\n'
          '1. Vào: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=794522024584\n'
          '2. Nhấn "Enable" để bật People API\n'
          '3. Đợi vài phút rồi thử lại.',
        );
      }
      throw AuthServiceException('Đăng nhập Google thất bại: $e');
    }
  }

  /// Gửi email đặt lại mật khẩu của Firebase
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException.fromFirebase(e);
    } catch (e) {
      throw AuthServiceException('Lỗi không xác định: $e');
    }
  }
  /// Đổi mật khẩu
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthServiceException('Chưa đăng nhập.');

    try {
      // 1. Re-authenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);

      // 2. Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException.fromFirebase(e);
    } catch (e) {
      throw AuthServiceException('Lỗi đổi mật khẩu: $e');
    }
  }
}

/// Exception đơn giản hoá thông báo lỗi Auth cho UI.
class AuthServiceException implements Exception {
  final String message;

  AuthServiceException(this.message);

  factory AuthServiceException.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthServiceException('Email không hợp lệ.');
      case 'user-disabled':
        return AuthServiceException('Tài khoản đã bị khoá.');
      case 'user-not-found':
        return AuthServiceException('Không tìm thấy tài khoản.');
      case 'wrong-password':
        return AuthServiceException('Sai mật khẩu.');
      case 'email-already-in-use':
        return AuthServiceException('Email đã được sử dụng.');
      case 'weak-password':
        return AuthServiceException('Mật khẩu quá yếu.');
      default:
        return AuthServiceException(
          e.message ?? 'Đã xảy ra lỗi xác thực. Mã lỗi: ${e.code}',
        );
    }
  }

  @override
  String toString() => 'AuthServiceException: $message';
}


