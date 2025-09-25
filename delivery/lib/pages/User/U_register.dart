import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class URegisterPage extends StatefulWidget {
  const URegisterPage({super.key});

  @override
  State<URegisterPage> createState() => _URegisterPageState();
}

class _URegisterPageState extends State<URegisterPage> {
  // --- Controller ---
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // --- Map & Image ---
  final MapController mapController = MapController();
  final ImagePicker picker = ImagePicker();
  XFile? image;
  LatLng currentPosition = const LatLng(16.246373, 103.251827);

  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void dispose() {
    // ✅ ป้องกัน error _dependents.isEmpty: is not true
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    mapController.dispose();
    super.dispose();
  }

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
                // -------- Username --------
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อผู้ใช้งาน",
                    hintText: "ชื่อผู้ใช้งาน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // -------- Phone --------
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

                // -------- Password --------
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

                // -------- Confirm Password --------
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

                // -------- Address (GPS) --------
                TextField(
                  controller: addressController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "ที่อยู่ (พิกัด)",
                    hintText: "กดปุ่มเพื่อดึงตำแหน่ง",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.blue),
                      onPressed: () async {
                        try {
                          Position position = await _determinePosition();
                          if (!mounted) return; // ✅ กัน setState หลัง dispose
                          if (position.latitude.isFinite &&
                              position.longitude.isFinite) {
                            String gpsText =
                                "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
                            setState(() {
                              currentPosition = LatLng(
                                position.latitude,
                                position.longitude,
                              );
                              addressController.text = gpsText;
                              mapController.move(currentPosition, 17);
                            });
                            log("📍 GPS: $gpsText");
                            Get.snackbar(
                              'ตำแหน่งปัจจุบัน',
                              gpsText,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } else {
                            throw 'ค่าพิกัดไม่ถูกต้อง';
                          }
                        } catch (e) {
                          if (!mounted) return;
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
                const SizedBox(height: 20),

                // -------- Map --------
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: currentPosition,
                      initialZoom: 15.2,
                      onTap: (tapPosition, point) {
                        if (!mounted) return;
                        if (point.latitude.isFinite &&
                            point.longitude.isFinite) {
                          setState(() {
                            currentPosition = point;
                            addressController.text =
                                "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                          });
                          log("🖱️ Map tapped: $point");
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                        userAgentPackageName: 'net.gonggang.osm_demo',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPosition,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // -------- Upload Image --------
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
                                  "เลือกรูปภาพ",
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
                                    if (!mounted) return;
                                    if (picked != null) {
                                      setState(() => image = picked);
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
                                    if (!mounted) return;
                                    if (picked != null) {
                                      setState(() => image = picked);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.file_upload_outlined, color: Colors.black54),
                        SizedBox(width: 8),
                        Text(
                          "เพิ่มรูปภาพ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // -------- Submit Button --------
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
                    onPressed: addData,
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

  // ---------- ดึงตำแหน่ง GPS ----------
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services ปิดอยู่ กรุณาเปิด GPS';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'สิทธิ์เข้าถึงตำแหน่งถูกปฏิเสธถาวร';
    }

    return await Geolocator.getCurrentPosition();
  }

  // ---------- บันทึกข้อมูล ----------
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
      if (image != null) {
        final file = File(image!.path);
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${image!.name}";
        final storageRef = FirebaseStorage.instance.ref().child(
          "user_images/$fileName",
        );
        await storageRef.putFile(file);
        imageUrl = await storageRef.getDownloadURL();
      }

      final data = {
        "username": usernameController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": hashedPassword,
        "address": addressController.text.trim(),
        "imageUrl": imageUrl ?? "",
      };

      await db.collection('user').doc(usernameController.text.trim()).set(data);

      if (!mounted) return;
      Get.snackbar(
        'สำเร็จ',
        'บันทึกข้อมูลเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.to(() => const ULoginPage());
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'ผิดพลาด',
        'บันทึกข้อมูลไม่สำเร็จ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
