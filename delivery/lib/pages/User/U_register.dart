import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final TextEditingController addressController =
      TextEditingController(); // พิกัด
  final TextEditingController detailController =
      TextEditingController(); // รายละเอียด

  final MapController mapController = MapController();
  final ImagePicker picker = ImagePicker();
  XFile? image;
  LatLng currentPosition = const LatLng(16.246373, 103.251827);

  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ✅ เก็บหลาย address
  List<Map<String, dynamic>> addresses = [];

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    detailController.dispose();
    mapController.dispose();
    super.dispose();
  }

  // ✅ เพิ่ม address เข้าลิสต์
  void addAddress() {
    if (addressController.text.isNotEmpty && detailController.text.isNotEmpty) {
      setState(() {
        addresses.add({
          "gps": addressController.text.trim(),
          "detail": detailController.text.trim(),
          "lat": currentPosition.latitude,
          "lng": currentPosition.longitude,
          "createdAt": DateTime.now(),
        });
        detailController.clear();
      });
      Get.snackbar(
        "สำเร็จ",
        "เพิ่มที่อยู่เรียบร้อยแล้ว",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "ข้อมูลไม่ครบ",
        "กรุณาเลือกพิกัดและใส่รายละเอียด",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
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
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อผู้ใช้งาน",
                    hintText: "ชื่อผู้ใช้งาน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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

                // ✅ พิกัด GPS
                TextField(
                  controller: addressController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "ที่อยู่ (พิกัด)",
                    hintText: "กดปุ่มหรือเลือกจากแผนที่",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.blue),
                      onPressed: () async {
                        try {
                          Position position = await _determinePosition();
                          if (!mounted) return;
                          final gpsText =
                              "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
                          setState(() {
                            currentPosition = LatLng(
                              position.latitude,
                              position.longitude,
                            );
                            addressController.text = gpsText;
                            mapController.move(currentPosition, 17);
                          });
                          Get.snackbar(
                            'ตำแหน่งปัจจุบัน',
                            gpsText,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
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
                const SizedBox(height: 12),

                // ✅ รายละเอียดที่อยู่
                TextField(
                  controller: detailController,
                  decoration: const InputDecoration(
                    labelText: "รายละเอียดที่อยู่",
                    hintText: "เช่น บ้าน, ที่ทำงาน, ร้าน ฯลฯ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // ปุ่มเพิ่มที่อยู่
                ElevatedButton.icon(
                  onPressed: addAddress,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text("เพิ่มที่อยู่"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),

                // แสดงรายการที่อยู่
                if (addresses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Column(
                    children: addresses.map((addr) {
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        title: Text(addr["detail"]),
                        subtitle: Text(addr["gps"]),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: currentPosition,
                      initialZoom: 15.2,
                      onTap: (tapPosition, point) {
                        if (!mounted) return;
                        setState(() {
                          currentPosition = point;
                          addressController.text =
                              "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                        });
                        log("🖱️ Map tapped: $point");
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

                // ✅ อัปโหลดรูป
                InkWell(
                  onTap: () async {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (!mounted) return;
                    if (picked != null) {
                      setState(() => image = picked);
                    }
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

                // -------- Submit --------
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
                      "ลงทะเบียน User",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // 🔹 ปุ่ม Sign in
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

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services ปิดอยู่';
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'สิทธิ์ถูกปฏิเสธถาวร';
    }
    return await Geolocator.getCurrentPosition();
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

    if (addresses.isEmpty) {
      Get.snackbar(
        'กรุณาเพิ่มที่อยู่',
        'ต้องมีที่อยู่อย่างน้อย 1 รายการ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final hashedPassword = sha256
        .convert(utf8.encode(passwordController.text.trim()))
        .toString();

    String? imageUrlSupabase;

    try {
      if (image != null) {
        final file = File(image!.path);
        final safeName = image!.name.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final fileName = "${DateTime.now().millisecondsSinceEpoch}_$safeName";

        final supaFileName = "user_images/$fileName";
        log("Uploading to Supabase path: $supaFileName");

        try {
          await Supabase.instance.client.storage
              .from('user')
              .upload(supaFileName, file);

          imageUrlSupabase = Supabase.instance.client.storage
              .from('user')
              .getPublicUrl(supaFileName);

          log("✅ Uploaded: $imageUrlSupabase");
        } on StorageException catch (e) {
          throw 'StorageException: ${e.message}';
        } catch (e) {
          throw 'Upload error: $e';
        }
      }

      final data = {
        "username": usernameController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": hashedPassword,
        "imageSupabase": imageUrlSupabase ?? "",
        "addresses": addresses,
      };

      await db
          .collection('user')
          .doc(usernameController.text.trim())
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      Get.snackbar(
        'สำเร็จ',
        'บันทึกข้อมูลเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.to(() => const ULoginPage());
    } catch (e, stack) {
      if (!mounted) return;
      log('❌ Error while saving user: $e');
      log('Stack trace: $stack');

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
