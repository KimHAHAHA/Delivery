import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:delivery/providers/rider_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class REditeProfilePage extends StatefulWidget {
  const REditeProfilePage({super.key});

  @override
  State<REditeProfilePage> createState() => _REditeProfilePageState();
}

class _REditeProfilePageState extends State<REditeProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();

  XFile? profileImage;
  XFile? vehicleImage;
  bool isLoading = false;

  final picker = ImagePicker();

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

  Future<void> _pickImage(bool isProfile) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isProfile) {
          profileImage = picked;
        } else {
          vehicleImage = picked;
        }
      });
    }
  }

  Future<void> _saveChanges(BuildContext context) async {
    final riderProvider = context.read<RiderProvider>();
    final username = riderProvider.username;
    if (username == null) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่พบข้อมูลผู้ใช้",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String? profileUrl = riderProvider.riderImageUrl;
      String? vehicleUrl = riderProvider.vehicleImageUrl;

      // ✅ อัปโหลดรูปโปรไฟล์
      if (profileImage != null) {
        final file = File(profileImage!.path);
        final fileName = "rider_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await supabase.storage.from('rider').upload(fileName, file);
        profileUrl = supabase.storage.from('rider').getPublicUrl(fileName);
      }

      // ✅ อัปโหลดรูปรถ
      if (vehicleImage != null) {
        final file = File(vehicleImage!.path);
        final fileName = "vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await supabase.storage.from('rider').upload(fileName, file);
        vehicleUrl = supabase.storage.from('rider').getPublicUrl(fileName);
      }

      // ✅ อัปเดตข้อมูลใน Firestore
      final data = {
        "username": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "vehicleController": vehicleController.text.trim(),
        "riderImageUrl": profileUrl,
        "vehicleImageUrl": vehicleUrl,
      };

      await FirebaseFirestore.instance
          .collection('rider')
          .doc(username)
          .update(data);

      // ✅ อัปเดตข้อมูลใน Provider ให้ตรงกับ Firestore
      riderProvider.setRiderData(
        uid: riderProvider.uid ?? "",
        username: nameController.text.trim(),
        phone: phoneController.text.trim(),
        vehicleController: vehicleController.text.trim(),
        riderImageUrl: profileUrl ?? riderProvider.riderImageUrl ?? "",
        vehicleImageUrl: vehicleUrl ?? riderProvider.vehicleImageUrl ?? "",
      );

      Get.snackbar(
        "สำเร็จ",
        "อัปเดตข้อมูลเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // ✅ กลับหน้าโปรไฟล์
      Get.off(() => const RProfilePage());
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถอัปเดตข้อมูลได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final rider = context.read<RiderProvider>();
    nameController.text = rider.username ?? "";
    phoneController.text = rider.phone ?? "";
    vehicleController.text = rider.vehicleController ?? "";
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
              TextField(
                controller: nameController,
                decoration: _inputDecoration("ชื่อไรเดอร์"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: _inputDecoration("เบอร์โทรศัพท์"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vehicleController,
                decoration: _inputDecoration("ทะเบียนรถ"),
              ),
              const SizedBox(height: 12),

              // รูปโปรไฟล์
              TextField(
                readOnly: true,
                decoration: _inputDecoration("เพิ่มรูปโปรไฟล์").copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.file_upload_outlined),
                    onPressed: () => _pickImage(true),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // รูปรถ
              TextField(
                readOnly: true,
                decoration: _inputDecoration("เพิ่มรูปยานพาหนะ").copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.file_upload_outlined),
                    onPressed: () => _pickImage(false),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                  onPressed: isLoading ? null : () => _saveChanges(context),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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
