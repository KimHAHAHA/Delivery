import 'package:flutter/material.dart';

class RiderProvider extends ChangeNotifier {
  String? username;
  String? phone;
  String? vehicleController;
  String? riderImageUrl;
  String? vehicleImageUrl;

  // ✅ เซ็ตข้อมูล Rider
  void setRiderData({
    required String username,
    required String phone,
    required String vehicleController,
    required String riderImageUrl,
    required String vehicleImageUrl,
  }) {
    this.username = username;
    this.phone = phone;
    this.vehicleController = vehicleController;
    this.riderImageUrl = riderImageUrl;
    this.vehicleImageUrl = vehicleImageUrl;
    notifyListeners();
  }

  // ✅ ล้างข้อมูลตอน Logout
  void clear() {
    username = null;
    phone = null;
    vehicleController = null;
    riderImageUrl = null;
    vehicleImageUrl = null;
    notifyListeners();
  }
}
