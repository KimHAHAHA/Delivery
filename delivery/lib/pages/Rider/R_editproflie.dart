import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class REditeProfilePage extends StatelessWidget {
  const REditeProfilePage({super.key});

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // พื้นหลังเขียวอ่อน
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
          "แก้ไขบัญชี",
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
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ชื่อ
              TextField(decoration: _inputDecoration("สมชาย")),
              const SizedBox(height: 12),

              // เบอร์
              TextField(decoration: _inputDecoration("081")),
              const SizedBox(height: 12),

              // ทะเบียนรถ
              TextField(decoration: _inputDecoration("ทะเบียนรถ")),
              const SizedBox(height: 12),

              // อัปโหลดโปรไฟล์
              TextField(
                readOnly: true,
                decoration: _inputDecoration(
                  "เพิ่มรูปโปรไฟล์",
                ).copyWith(suffixIcon: const Icon(Icons.file_upload_outlined)),
              ),
              const SizedBox(height: 12),

              // อัปโหลดบัตร/เอกสาร
              TextField(
                readOnly: true,
                decoration: _inputDecoration(
                  "เพิ่มรูปบัตรพนักงาน",
                ).copyWith(suffixIcon: const Icon(Icons.file_upload_outlined)),
              ),
              const SizedBox(height: 20),

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
                  onPressed: () {
                    Get.to(() => RProfilePage());
                  },
                  child: const Text(
                    "ยืนยันการแก้ไข",
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
}
