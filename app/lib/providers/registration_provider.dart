import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/user_model.dart';

/// Provider lưu tạm dữ liệu đăng ký multi-step trước khi lưu Firestore.
class RegistrationProvider extends ChangeNotifier {
  String email = '';
  String password = '';

  String fullName = '';
  String phoneNumber = '';
  String gender = 'other';
  DateTime? birthday;

  Uint8List? avatarBytes;
  String? avatarUrl;

  void setAccount({
    required String email,
    required String password,
  }) {
    this.email = email;
    this.password = password;
    notifyListeners();
  }

  void setProfileInfo({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime? birthday,
  }) {
    this.fullName = fullName;
    this.phoneNumber = phoneNumber;
    this.gender = gender;
    this.birthday = birthday;
    notifyListeners();
  }

  void setAvatarBytes(Uint8List? bytes) {
    avatarBytes = bytes;
    notifyListeners();
  }

  void setAvatarUrl(String? url) {
    avatarUrl = url;
    notifyListeners();
  }

  UserModel toUserModel({
    required String uid,
    required String avatarUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      gender: gender,
      birthday: birthday,
      avatarUrl: avatarUrl,
    );
  }
}


