import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/Rider/R_register.dart';
import 'package:delivery/pages/User/U_home.dart';
import 'package:delivery/pages/User/U_register.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class ULoginPage extends StatefulWidget {
  const ULoginPage({super.key});

  @override
  State<ULoginPage> createState() => _ULoginPageState();
}

class _ULoginPageState extends State<ULoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // พื้นหลังเขียวอ่อน
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/Logo.png", // ใส่ path ของโลโก้คุณ
                    fit: BoxFit.cover,
                    width: 140,
                    height: 140,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // กล่องฟอร์ม
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Username
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: "ชื่อผู้ใช้งาน",
                        hintText: "ชื่อผู้ใช้งาน",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "รหัสผ่าน",
                        hintText: "รหัสผ่าน",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ปุ่มเข้าสู่ระบบ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          loginUser();
                        },
                        child: const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ลิงก์สมัครสมาชิก
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.to(() => const URegisterPage());
                          },
                          child: const Text(
                            "ลงทะเบียน User",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => const RRegisterPage());
                          },
                          child: const Text(
                            "ลงทะเบียน Rider",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void loginUser() async {
    final username = usernameController.text.trim();
    final passwordInput = passwordController.text.trim();

    if (username.isEmpty || passwordInput.isEmpty) {
      Get.snackbar('แจ้งเตือน', 'กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(username)
          .get();

      if (!doc.exists) {
        Get.snackbar('ผิดพลาด', 'ไม่พบชื่อผู้ใช้');
        return;
      }

      final hashedInput = sha256.convert(utf8.encode(passwordInput)).toString();

      final storedHashedPassword = doc['password'] as String;

      if (hashedInput == storedHashedPassword) {
        Get.snackbar(
          'สำเร็จ',
          'เข้าสู่ระบบเรียบร้อย',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // ไปหน้า Home หรือหน้าที่ต้องการ
        Get.to(() => const UHomePage());
      } else {
        Get.snackbar(
          'ผิดพลาด',
          'รหัสผ่านไม่ถูกต้อง',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'ผิดพลาด',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
