import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_proflie.dart';
import 'package:delivery/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ✅ โหลดค่าปัจจุบันจาก Provider
    final user = context.read<UserProvider>();
    nameController.text = user.username ?? "";
    phoneController.text = user.phone ?? "";
  }

  Future<void> _saveProfile() async {
    final username = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (username.isEmpty || phone.isEmpty) {
      Get.snackbar(
        "ผิดพลาด",
        "กรุณากรอกข้อมูลให้ครบ",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final userProvider = context.read<UserProvider>();
      final currentUsername = userProvider.username;

      if (currentUsername == null) {
        Get.snackbar(
          "ผิดพลาด",
          "ไม่พบผู้ใช้ในระบบ",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // ✅ update Firestore
      final docRef = FirebaseFirestore.instance
          .collection("user")
          .doc(currentUsername);

      await docRef.update({"username": username, "phone": phone});

      // ✅ update Provider
      userProvider.setUserData(
        uid: userProvider.uid ?? "",
        username: username,
        phone: phone,
        address: userProvider.address ?? "",
        imageUrl: userProvider.imageUrl ?? "",
      );

      Get.snackbar(
        "สำเร็จ",
        "บันทึกข้อมูลเรียบร้อย",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.off(() => const UProfilePage());
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถบันทึกได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ชื่อ
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "ชื่อผู้ใช้งาน",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // เบอร์โทร
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "เบอร์โทร",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // ปุ่มบันทึก
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
                  onPressed: _saveProfile,
                  child: const Text(
                    "บันทึก",
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
