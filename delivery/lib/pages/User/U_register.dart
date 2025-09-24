import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class URegisterPage extends StatefulWidget {
  const URegisterPage({super.key});

  @override
  State<URegisterPage> createState() => _URegisterPageState();
}

class _URegisterPageState extends State<URegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  var db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // สีพื้นหลังเขียวอ่อน
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                // ชื่อผู้ใช้
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อผู้ใช้งาน",
                    hintText: "ชื่อผู้ใช้งาน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // เบอร์โทรศัพท์
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "หมายเลขโทรศัพท์",
                    hintText: "หมายเลขโทรศัพท์",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // รหัสผ่าน
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "รหัสผ่าน",
                    hintText: "รหัสผ่าน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ยืนยันรหัสผ่าน
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "ยืนยันรหัสผ่าน",
                    hintText: "ยืนยันรหัสผ่าน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ที่อยู่
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: "ที่อยู่",
                    hintText: "ที่อยู่",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.location_on_outlined),
                      onPressed: () {
                        // TODO: กดเลือกที่อยู่
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // เพิ่มรูปผู้ใช้
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "เพิ่มรูปผู้ใช้",
                    hintText: "เพิ่มรูปผู้ใช้",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.file_upload_outlined),
                      onPressed: () {
                        // TODO: เลือกรูป
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ปุ่มสมัครสมาชิก
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
                      addData();
                    },
                    child: const Text(
                      "ลงทะเบียน",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addData() async {
    final hashedPassword = sha256
        .convert(utf8.encode(passwordController.text.trim()))
        .toString();

    var data = {
      "username": usernameController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": hashedPassword,
      "address": addressController.text.trim(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(usernameController.text.trim())
          .set(data);

      // แจ้งเตือนเมื่อสำเร็จ
      Get.snackbar(
        'สำเร็จ',
        'บันทึกข้อมูลเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Get.to(() => const ULoginPage());
    } catch (e) {
      Get.snackbar(
        'ผิดพลาด',
        'บันทึกข้อมูลไม่สำเร็จ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
