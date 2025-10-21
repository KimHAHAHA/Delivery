import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:delivery/providers/rider_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class RChangePasswordPage extends StatefulWidget {
  const RChangePasswordPage({super.key});

  @override
  State<RChangePasswordPage> createState() => _RChangePasswordPageState();
}

class _RChangePasswordPageState extends State<RChangePasswordPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> _changePassword(BuildContext context) async {
    final riderProvider = context.read<RiderProvider>();
    final username = riderProvider.username;
    if (username == null) {
      Get.snackbar(
        "ข้อผิดพลาด",
        "ไม่พบข้อมูลผู้ใช้งาน",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      Get.snackbar(
        "ข้อมูลไม่ครบ",
        "กรุณากรอกข้อมูลให้ครบทุกช่อง",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar(
        "รหัสไม่ตรงกัน",
        "กรุณายืนยันรหัสผ่านใหม่ให้ตรงกัน",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ ดึงข้อมูล rider จาก Firestore
      final doc = await FirebaseFirestore.instance
          .collection('rider')
          .doc(username)
          .get();
      if (!doc.exists) {
        throw "ไม่พบบัญชีผู้ใช้";
      }

      final data = doc.data();
      final storedPassword = data?['password'];

      // ✅ แปลงรหัสผ่านเก่าเป็น hash แล้วเทียบ
      final oldHashed = sha256.convert(utf8.encode(oldPass)).toString();
      if (oldHashed != storedPassword) {
        throw "รหัสผ่านเก่าไม่ถูกต้อง";
      }

      // ✅ อัปเดตรหัสผ่านใหม่ (hash ก่อนบันทึก)
      final newHashed = sha256.convert(utf8.encode(newPass)).toString();
      await FirebaseFirestore.instance.collection('rider').doc(username).update(
        {'password': newHashed},
      );

      Get.snackbar(
        "สำเร็จ",
        "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.off(() => const RProfilePage());
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "เปลี่ยนรหัสผ่าน",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "รหัสผ่านเก่า",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "รหัสผ่านใหม่",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "ยืนยันรหัสผ่านใหม่",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
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
                  onPressed: isLoading ? null : () => _changePassword(context),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ยืนยัน", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
