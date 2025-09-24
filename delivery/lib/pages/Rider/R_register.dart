import 'package:delivery/pages/User/U_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class RRegisterPage extends StatefulWidget {
  const RRegisterPage({super.key});

  @override
  State<RRegisterPage> createState() => _RRegisterPageState();
}

class _RRegisterPageState extends State<RRegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // สีเขียวอ่อนพื้นหลัง
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
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อผู้ใช้งาน",
                    hintText: "ชื่อผู้ใช้งาน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // เบอร์โทรศัพท์
                TextField(
                  controller: _phoneController,
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
                  controller: _passwordController,
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
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "ยืนยันรหัสผ่าน",
                    hintText: "ยืนยันรหัสผ่าน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ทะเบียนรถ
                TextField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: "ทะเบียนรถ",
                    hintText: "ทะเบียนรถ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // อัพโหลดรูปโปรไฟล์ Rider
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "เพิ่มรูปไรเดอร์",
                    hintText: "เพิ่มรูปไรเดอร์",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.file_upload_outlined),
                      onPressed: () {
                        // TODO: เลือกรูปโปรไฟล์
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // อัพโหลดเอกสารพาหนะ
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "เพิ่มรูปยานพาหนะ",
                    hintText: "เพิ่มรูปยานพาหนะ",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.file_upload_outlined),
                      onPressed: () {
                        // TODO: เลือกรูปยานพาหนะ
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ปุ่มสมัคร Rider
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
                      Get.to(() => const ULoginPage());
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
}
