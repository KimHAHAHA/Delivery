import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_proflie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:delivery/providers/user_provider.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "เปลี่ยนรหัสผ่าน",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // รหัสผ่านเก่า
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "รหัสผ่านปัจจุบัน",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // รหัสผ่านใหม่
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "รหัสผ่านใหม่",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // ยืนยันรหัสผ่านใหม่
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "ยืนยันรหัสผ่านใหม่",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // ปุ่มยืนยัน
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
                  onPressed: () async {
                    await _changePassword(
                      context,
                      oldPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                      confirmPasswordController.text.trim(),
                    );
                  },
                  child: const Text(
                    "ยืนยัน",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    String oldPass,
    String newPass,
    String confirmPass,
  ) async {
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      Get.snackbar(
        "ผิดพลาด",
        "กรุณากรอกข้อมูลให้ครบ",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar(
        "ผิดพลาด",
        "รหัสผ่านใหม่และยืนยันไม่ตรงกัน",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final username = userProvider.username;

    if (username == null) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่พบข้อมูลผู้ใช้",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection("user").doc(username);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่พบข้อมูลผู้ใช้ในระบบ",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final data = snapshot.data()!;
    final storedPassword = data['password'];

    // hash ของรหัสผ่านเก่า
    final oldHashed = sha256.convert(utf8.encode(oldPass)).toString();

    if (storedPassword != oldHashed) {
      Get.snackbar(
        "ผิดพลาด",
        "รหัสผ่านปัจจุบันไม่ถูกต้อง",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // hash ของรหัสผ่านใหม่
    final newHashed = sha256.convert(utf8.encode(newPass)).toString();

    await docRef.update({"password": newHashed});

    Get.snackbar(
      "สำเร็จ",
      "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Get.off(() => const UProfilePage()); // กลับไปหน้าโปรไฟล์
  }
}
