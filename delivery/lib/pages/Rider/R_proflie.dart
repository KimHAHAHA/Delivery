import 'package:delivery/pages/Rider/R_changpassword.dart';
import 'package:delivery/pages/Rider/R_editproflie.dart';
import 'package:delivery/pages/Rider/R_home.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RProfilePage extends StatefulWidget {
  const RProfilePage({super.key});

  @override
  State<RProfilePage> createState() => _RProfilePageState();
}

class _RProfilePageState extends State<RProfilePage> {
  int _selectedIndex = 1; // ค่าเริ่มต้น: บัญชี

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Get.to(() => const RHomePage());
        break;
      case 1:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // สีพื้นหลังเขียวอ่อน
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
              radius: 60,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 70, color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),

            // ข้อมูลผู้ใช้
            const Text(
              "ชื่อ : สมชาย",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const Text(
              "เบอร์ : 081",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 20),

            // ปุ่มเปลี่ยนรหัสผ่าน (ลิงก์)
            TextButton(
              onPressed: () {
                Get.to(() => const RChangePasswordPage());
              },
              child: const Text(
                "เปลี่ยนรหัสผ่าน",
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),

            // ปุ่มแก้ไขบัญชี
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Get.to(() => const REditeProfilePage());
              },
              child: const Text("แก้ไขบัญชี"),
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
                    Get.offAll(() => const ULoginPage()); // ออกจากระบบ
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }
}
