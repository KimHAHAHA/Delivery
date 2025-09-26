import 'package:delivery/pages/User/%E0%B9%8AU_chagepassword.dart';
import 'package:delivery/pages/User/%E0%B9%8AU_editproflie.dart';
import 'package:delivery/pages/User/%E0%B9%8AU_track.dart';
import 'package:delivery/pages/User/U_address.dart';
import 'package:delivery/pages/User/U_home.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class UProfilePage extends StatefulWidget {
  const UProfilePage({super.key});

  @override
  State<UProfilePage> createState() => _UProfilePageState();
}

class _UProfilePageState extends State<UProfilePage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Get.to(() => const UHomePage());
        break;

      case 1:
        Get.to(() => const UTrackPage());
        break;

      case 2:
        Get.to(() => const UProfilePage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // เขียวอ่อน
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // หัวข้อ
            const Text(
              "บัญชี",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),

            // ข้อมูลผู้ใช้
            const Text(
              "ชื่อ : สมชาย\nเบอร์ : 081\nที่อยู่ : บ้าน",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 30),

            // ปุ่มจัดการ
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton("ที่อยู่"),
                const SizedBox(width: 10),
                _buildActionButton("แก้ไขบัญชี"),
                const SizedBox(width: 10),
                _buildActionButton("เปลี่ยนรหัส"),
              ],
            ),

            const Spacer(),

            // ปุ่มออกจากระบบ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Get.to(() => const ULoginPage());
                  },
                  child: const Text(
                    "ออกจากระบบ",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: "ติดตามการรับ",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มดำเล็กๆ
  Widget _buildActionButton(String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () {
        switch (text) {
          case "ที่อยู่":
            Get.to(() => const AddressPage());
            break;

          case "แก้ไขบัญชี":
            Get.to(() => const EditProfilePage());
            break;

          case "เปลี่ยนรหัส":
            Get.to(() => const ChangePasswordPage());
            break;
        }
      },
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
