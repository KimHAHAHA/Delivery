import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  String? _phone;
  String? _address;
  String? _imageUrl; // ✅ เพิ่มเก็บรูปภาพ

  String? get username => _username;
  String? get phone => _phone;
  String? get address => _address;
  String? get imageUrl => _imageUrl;

  void setUserData({
    required String username,
    required String phone,
    required String address,
    required String imageUrl,
  }) {
    _username = username;
    _phone = phone;
    _address = address;
    _imageUrl = imageUrl;
    notifyListeners();
  }

  void clear() {
    _username = null;
    _phone = null;
    _address = null;
    _imageUrl = null;
    notifyListeners();
  }
}
