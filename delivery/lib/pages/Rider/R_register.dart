import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:image_picker/image_picker.dart';

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
  XFile? RiderProfileImage;
  XFile? vehicleImage;

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

                // ทะเบียนรถ
                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(
                    labelText: "ทะเบียนรถ",
                    hintText: "ทะเบียนรถ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // อัพโหลดรูปโปรไฟล์ Rider
                // อัพโหลดรูปโปรไฟล์ Rider
                // เพิ่มรูปไรเดอร์ (เลือกได้เหมือน bottom sheet สวยๆ)
                InkWell(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (BuildContext bc) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "เลือกรูปไรเดอร์",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.green.shade100,
                                    child: const Icon(
                                      Icons.photo_camera,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                  ),
                                  title: const Text(
                                    'ถ่ายภาพด้วยกล้อง',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked = await picker.pickImage(
                                      source: ImageSource.camera,
                                    );
                                    if (picked != null) {
                                      setState(
                                        () => RiderProfileImage = picked,
                                      );
                                    }
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(
                                      Icons.photo_library,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                  ),
                                  title: const Text(
                                    'เลือกรูปจากแกลเลอรี',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked != null) {
                                      setState(
                                        () => RiderProfileImage = picked,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            RiderProfileImage != null
                                ? RiderProfileImage!.name
                                : 'เพิ่มรูปไรเดอร์',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.file_upload_outlined,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // อัพโหลดเอกสารพาหนะ
                // อัพโหลดรูปยานพาหนะ
                // เพิ่มรูปยานพาหนะ (เลือกได้จากกล้องหรือแกลเลอรี)
                InkWell(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (BuildContext bc) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // handle bar ด้านบน
                                Container(
                                  width: 60,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "เลือกรูปยานพาหนะ",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ปุ่มถ่ายด้วยกล้อง
                                ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(
                                      Icons.photo_camera,
                                      color: Colors.deepOrange,
                                      size: 28,
                                    ),
                                  ),
                                  title: const Text(
                                    'ถ่ายภาพด้วยกล้อง',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked = await picker.pickImage(
                                      source: ImageSource.camera,
                                    );
                                    if (picked != null) {
                                      setState(() => vehicleImage = picked);
                                    }
                                  },
                                ),
                                const Divider(),

                                // ปุ่มเลือกจากแกลเลอรี
                                ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(
                                      Icons.photo_library,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                  ),
                                  title: const Text(
                                    'เลือกรูปจากแกลเลอรี',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked != null) {
                                      setState(() => vehicleImage = picked);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            vehicleImage != null
                                ? vehicleImage!.name
                                : 'เพิ่มรูปยานพาหนะ',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.file_upload_outlined,
                          color: Colors.black54,
                        ),
                      ],
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
                      addDataRider();
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

  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        RiderProfileImage = picked;
      });
    }
  }

  Future<void> pickVehicleImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        vehicleImage = picked;
      });
    }
  }

  void addDataRider() async {
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      Get.snackbar(
        'รหัสผ่านไม่ตรงกัน',
        'กรุณากรอกรหัสผ่านให้ตรงกัน',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final hashedPassword = sha256
        .convert(utf8.encode(passwordController.text.trim()))
        .toString();

    String? imageUrl;
    String? vehicleImageUrl;

    try {
      // ✅ ถ้ามีการเลือกรูป
      if (RiderProfileImage != null) {
        File file = File(RiderProfileImage!.path);
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${RiderProfileImage!.name}";

        final storageRef = FirebaseStorage.instance.ref().child(
          "rider_profiles/$fileName",
        );

        await storageRef.putFile(file);
        imageUrl = await storageRef.getDownloadURL();
      }

      if (vehicleImage != null) {
        File file = File(vehicleImage!.path);
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${vehicleImage!.name}";
        final storageRef = FirebaseStorage.instance.ref().child(
          "vehicle_images/$fileName",
        );
        await storageRef.putFile(file);
        vehicleImageUrl = await storageRef.getDownloadURL();
      }

      // ✅ เก็บข้อมูลลง Firestore
      var data = {
        "username": usernameController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": hashedPassword,
        "vehicleController": vehicleController.text.trim(),
        "imageUrl": imageUrl ?? "",
        "vehicleImageUrl": vehicleImageUrl ?? "",
      };
      await FirebaseFirestore.instance
          .collection('rider')
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
