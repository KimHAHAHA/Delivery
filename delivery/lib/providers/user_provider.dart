import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _uid; // ✅ เพิ่ม UID ของผู้ใช้
  String? _username;
  String? _phone;
  String? _address;
  String? _imageUrl;

  // ✅ Getter
  String? get uid => _uid;
  String? get username => _username;
  String? get phone => _phone;
  String? get address => _address;
  String? get imageUrl => _imageUrl;

  // ✅ Setter สำหรับตั้งค่าผู้ใช้ทั้งหมด
  void setUserData({
    required String uid,
    required String username,
    required String phone,
    required String address,
    required String imageUrl,
  }) {
    _uid = uid;
    _username = username;
    _phone = phone;
    _address = address;
    _imageUrl = imageUrl;
    notifyListeners();
  }

  // ✅ อัปเดตที่อยู่
  void updateAddress(String newAddress) {
    _address = newAddress;
    notifyListeners();
  }

  // ✅ ล้างข้อมูลเมื่อออกจากระบบ
  void clear() {
    _uid = null;
    _username = null;
    _phone = null;
    _address = null;
    _imageUrl = null;
    notifyListeners();
  }
}
