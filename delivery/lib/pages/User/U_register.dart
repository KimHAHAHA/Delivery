import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
  double? latitude;
  double? longitude;

  final ImagePicker picker = ImagePicker();
  XFile? image;

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

                // ที่อยู่ + GPS
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: "ที่อยู่",
                    hintText: "ที่อยู่",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.location_on_outlined),
                      onPressed: () async {
                        try {
                          Position position = await _determinePosition();
                          String gpsText =
                              "${position.latitude}, ${position.longitude}";

                          setState(() {
                            addressController.text = gpsText;
                          });

                          log("📍 GPS: $gpsText");
                          Get.snackbar(
                            'ตำแหน่งปัจจุบัน',
                            gpsText,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'ผิดพลาด',
                            'ไม่สามารถดึงตำแหน่งได้: $e',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                    ),
                  ),
                ),

                // เพิ่มรูปผู้ใช้
                InkWell(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext bc) {
                        return SafeArea(
                          child: Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text('ถ่ายภาพด้วยกล้อง'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  image = await picker.pickImage(
                                    source: ImageSource.camera,
                                  );
                                  setState(() {});
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('เลือกรูปจากแกลเลอรี'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: image == null
                        ? const Center(
                            child: Icon(Icons.file_upload_outlined, size: 40),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(image!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),

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

    try {
      // ✅ ถ้ามีการเลือกรูป
      if (image != null) {
        File file = File(image!.path);
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${image!.name}";

        // อัปโหลดไป Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child(
          "user_images/$fileName",
        );

        try {
          final uploadTask = await storageRef.putFile(file);
          log("✅ Upload success: ${uploadTask.metadata?.fullPath}");

          // ดึง URL ของไฟล์
          imageUrl = await storageRef.getDownloadURL();
          log("✅ Uploaded image URL: $imageUrl");
        } catch (e) {
          log("❌ Upload failed: $e");
          throw e;
        }
      }

      // ✅ เก็บข้อมูลลง Firestore
      var data = {
        "username": usernameController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": hashedPassword,
        "address": addressController.text.trim(),
        "imageUrl": imageUrl ?? "",
      };

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

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
