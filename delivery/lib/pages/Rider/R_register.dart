import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RRegisterPage extends StatefulWidget {
  const RRegisterPage({super.key});

  @override
  State<RRegisterPage> createState() => _RRegisterPageState();
}

class _RRegisterPageState extends State<RRegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController vehicleController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  XFile? riderProfileImage;
  XFile? vehicleImage;
  bool isLoading = false; // ✅ สถานะโหลดดิ้ง

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
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
                _buildTextField(usernameController, "ชื่อผู้ใช้งาน"),
                const SizedBox(height: 16),
                _buildTextField(
                  phoneController,
                  "หมายเลขโทรศัพท์",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(passwordController, "รหัสผ่าน", obscure: true),
                const SizedBox(height: 16),
                _buildTextField(
                  confirmPasswordController,
                  "ยืนยันรหัสผ่าน",
                  obscure: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(vehicleController, "ทะเบียนรถ"),
                const SizedBox(height: 16),

                // ✅ อัปโหลดรูปโปรไฟล์
                _buildUploadBox(
                  title: "เพิ่มรูปโปรไฟล์ไรเดอร์",
                  pickedFile: riderProfileImage,
                  onPick: () async {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null)
                      setState(() => riderProfileImage = picked);
                  },
                ),
                const SizedBox(height: 16),

                // ✅ อัปโหลดรูปรถ
                _buildUploadBox(
                  title: "เพิ่มรูปยานพาหนะ",
                  pickedFile: vehicleImage,
                  onPick: () async {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) setState(() => vehicleImage = picked);
                  },
                ),
                const SizedBox(height: 24),

                // ✅ ปุ่มสมัคร
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoading ? Colors.grey : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : addDataRider,
                    child: isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "กำลังลงทะเบียน...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            "ลงทะเบียน Rider",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Get.to(() => const ULoginPage()),
                  child: const Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
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

  /// 🔹 ช่องกรอกข้อความพื้นฐาน
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// 🔹 กล่องอัปโหลดรูป
  Widget _buildUploadBox({
    required String title,
    required XFile? pickedFile,
    required Function() onPick,
  }) {
    return InkWell(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                pickedFile != null ? pickedFile.name : title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const Icon(Icons.file_upload_outlined, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  /// ✅ ฟังก์ชันลงทะเบียน Rider (มีโหลดดิ้ง + ตรวจข้อมูลครบ)
  void addDataRider() async {
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    final vehicle = vehicleController.text.trim();

    // 🔸 ตรวจช่องว่างทั้งหมด
    if (username.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        vehicle.isEmpty ||
        riderProfileImage == null ||
        vehicleImage == null) {
      Get.snackbar(
        "ข้อมูลไม่ครบ",
        "กรุณากรอกทุกช่องและเลือกรูปภาพให้ครบ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // 🔸 ตรวจพาสไม่ตรงกัน
    if (password != confirm) {
      Get.snackbar(
        "รหัสผ่านไม่ตรงกัน",
        "กรุณากรอกให้ตรงกัน",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ เริ่มโหลดดิ้ง
    setState(() => isLoading = true);
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final supabase = Supabase.instance.client;
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      String? riderImageUrl;
      String? vehicleImageUrl;
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(username)
          .get();
      final riderDoc = await FirebaseFirestore.instance
          .collection('rider')
          .doc(username)
          .get();

      if (userDoc.exists || riderDoc.exists) {
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar(
          'ชื่อผู้ใช้งานซ้ำ',
          'ชื่อ "$username" ถูกใช้แล้ว กรุณาเลือกชื่ออื่น',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => isLoading = false);
        return; // ❌ หยุดการทำงาน
      }

      // 🔹 อัปโหลดรูปโปรไฟล์
      if (riderProfileImage != null) {
        final file = File(riderProfileImage!.path);
        final fileName =
            "rider_profiles/${DateTime.now().millisecondsSinceEpoch}_${riderProfileImage!.name}";
        await supabase.storage.from('rider').upload(fileName, file);
        riderImageUrl = supabase.storage.from('rider').getPublicUrl(fileName);
      }

      // 🔹 อัปโหลดรูปรถ
      if (vehicleImage != null) {
        final file = File(vehicleImage!.path);
        final fileName =
            "vehicle_images/${DateTime.now().millisecondsSinceEpoch}_${vehicleImage!.name}";
        await supabase.storage.from('rider').upload(fileName, file);
        vehicleImageUrl = supabase.storage.from('rider').getPublicUrl(fileName);
      }

      // 🔹 บันทึก Firestore
      final data = {
        "username": username,
        "phone": phone,
        "password": hashedPassword,
        "vehicleController": vehicle,
        "riderImageUrl": riderImageUrl ?? "",
        "vehicleImageUrl": vehicleImageUrl ?? "",
      };

      await FirebaseFirestore.instance
          .collection('rider')
          .doc(username)
          .set(data);

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "สำเร็จ",
        "ลงทะเบียนสำเร็จแล้ว 🎉",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAll(() => const ULoginPage());
    } catch (e, stack) {
      if (Get.isDialogOpen ?? false) Get.back();
      log("❌ Error: $e\n$stack");
      Get.snackbar(
        "ผิดพลาด",
        "บันทึกข้อมูลไม่สำเร็จ: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
