import 'package:flutter/material.dart';

class RiderProvider extends ChangeNotifier {
  String? uid;
  String? username;
  String? phone;
  String? vehicleController;
  String? riderImageUrl;
  String? vehicleImageUrl;
  double? lat;
  double? lng;

  // ✅ เซ็ตข้อมูล Rider ตอน Login หรือ Load จาก Firestore
  void setRiderData({
    required String uid,
    required String username,
    required String phone,
    required String vehicleController,
    required String riderImageUrl,
    required String vehicleImageUrl,
  }) {
    this.uid = uid;
    this.username = username;
    this.phone = phone;
    this.vehicleController = vehicleController;
    this.riderImageUrl = riderImageUrl;
    this.vehicleImageUrl = vehicleImageUrl;
    notifyListeners();
  }

  // ✅ อัปเดตพิกัดปัจจุบันของไรเดอร์
  void setLocation(double lat, double lng) {
    this.lat = lat;
    this.lng = lng;
    notifyListeners();
  }

  // ✅ ล้างข้อมูลตอน Logout
  void clear() {
    uid = null;
    username = null;
    phone = null;
    vehicleController = null;
    riderImageUrl = null;
    vehicleImageUrl = null;
    lat = null;
    lng = null;
    notifyListeners();
  }
}
