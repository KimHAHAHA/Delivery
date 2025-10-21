import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_proflie.dart';
import 'package:delivery/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditImagePage extends StatefulWidget {
  const EditImagePage({super.key});

  @override
  State<EditImagePage> createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> {
  File? _imageFile;
  final picker = ImagePicker();
  final supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      Get.snackbar(
        "ผิดพลาด",
        "กรุณาเลือกรูปก่อน",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // ✅ เปิด Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false, // กดข้างนอกไม่ให้ปิด
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );

      final userProvider = context.read<UserProvider>();
      final username = userProvider.username;

      if (username == null) {
        Navigator.pop(context); // ปิด loading
        Get.snackbar(
          "ผิดพลาด",
          "ไม่พบข้อมูลผู้ใช้",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // ✅ อัปโหลดไป Supabase Storage
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${username}.jpg";
      final fileBytes = await _imageFile!.readAsBytes();

      await supabase.storage
          .from("user")
          .uploadBinary("user_images/$fileName", fileBytes);

      final publicUrl = supabase.storage
          .from("user")
          .getPublicUrl("user_images/$fileName");

      // ✅ อัปเดต Firestore
      await FirebaseFirestore.instance.collection("user").doc(username).update({
        "imageSupabase": publicUrl,
      });

      // ✅ อัปเดต Provider
      userProvider.setUserData(
        uid: userProvider.uid ?? "",
        username: userProvider.username ?? "",
        phone: userProvider.phone ?? "",
        address: userProvider.address ?? "",
        imageUrl: publicUrl,
      );

      Navigator.pop(context); // ปิด loading

      Get.snackbar(
        "สำเร็จ",
        "แก้ไขรูปภาพเรียบร้อย",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.off(() => const UProfilePage());
    } catch (e) {
      Navigator.pop(context); // ปิด loading
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถอัปโหลดรูปได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        title: const Text(
          "แก้ไขรูปภาพโปรไฟล์",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (userProvider.imageUrl != null &&
                            userProvider.imageUrl!.isNotEmpty
                        ? NetworkImage(userProvider.imageUrl!)
                        : const AssetImage("assets/images/Logo.png")
                              as ImageProvider),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text("เลือกรูปจากเครื่อง"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "บันทึก",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
