import 'package:delivery/pages/Rider/R_changpassword.dart';
import 'package:delivery/pages/Rider/R_editproflie.dart';
import 'package:delivery/pages/Rider/R_home.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:delivery/providers/rider_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class RProfilePage extends StatefulWidget {
  const RProfilePage({super.key});

  @override
  State<RProfilePage> createState() => _RProfilePageState();
}

class _RProfilePageState extends State<RProfilePage> {
  int _selectedIndex = 1;
  bool isLoggingOut = false; // ✅ state โหลดดิ้ง

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
    final riderProvider = context.watch<RiderProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
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
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage:
                  riderProvider.riderImageUrl != null &&
                      riderProvider.riderImageUrl!.isNotEmpty
                  ? NetworkImage(riderProvider.riderImageUrl!)
                  : null,
              child:
                  riderProvider.riderImageUrl == null ||
                      riderProvider.riderImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 70, color: Colors.deepPurple)
                  : null,
            ),
            const SizedBox(height: 20),

            // ข้อมูลผู้ใช้
            Text(
              "ชื่อ : ${riderProvider.username ?? '-'}",
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            Text(
              "เบอร์ : ${riderProvider.phone ?? '-'}",
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 20),

            // ปุ่มเปลี่ยนรหัสผ่าน
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
                  onPressed: isLoggingOut
                      ? null
                      : () async {
                          setState(() => isLoggingOut = true);

                          // ✅ แสดงโหลดดิ้งแบบ Dialog
                          Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false,
                          );

                          await Future.delayed(const Duration(seconds: 2));

                          // เคลียร์ข้อมูลและกลับไปหน้า login
                          riderProvider.clear();
                          if (Get.isDialogOpen ?? false) Get.back();

                          Get.offAll(() => const ULoginPage());

                          setState(() => isLoggingOut = false);
                        },
                  child: isLoggingOut
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "กำลังออกจากระบบ...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
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
