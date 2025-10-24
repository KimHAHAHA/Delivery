import 'dart:convert';
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
  final TextEditingController addressController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  final MapController mapController = MapController();
  final ImagePicker picker = ImagePicker();
  XFile? image;
  bool isLoading = false; // ✅ ตัวแปรโหลดดิ้ง
  LatLng currentPosition = const LatLng(16.246373, 103.251827);
  final FirebaseFirestore db = FirebaseFirestore.instance;
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
                // 🔹 ช่องกรอกข้อมูล
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

                // 🔹 ที่อยู่ (GPS)
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
                _buildTextField(detailController, "รายละเอียดที่อยู่"),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: addAddress,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text("เพิ่มที่อยู่"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),

                if (addresses.isNotEmpty)
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

                const SizedBox(height: 20),

                // 🔹 แผนที่
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: currentPosition,
                      initialZoom: 15.2,
                      onTap: (tapPosition, point) {
                        setState(() {
                          currentPosition = point;
                          addressController.text =
                              "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                        });
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

                // 🔹 อัปโหลดรูป
                InkWell(
                  onTap: () async {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() => image = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.file_upload_outlined,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          image == null ? "เพิ่มรูปภาพ" : "เลือกรูปแล้ว ✅",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 ปุ่มสมัคร
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
                    onPressed: isLoading ? null : addData,
                    child: isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
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
                            "ลงทะเบียน User",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

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

  // ✅ helper UI
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

  // ✅ ฟังก์ชันสมัคร (มีโหลดดิ้ง + ตรวจ username ซ้ำ)
  void addData() async {
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        image == null ||
        addresses.isEmpty) {
      Get.snackbar(
        'ข้อมูลไม่ครบ',
        'กรุณากรอกทุกช่องและเพิ่มที่อยู่/รูปภาพ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (password != confirm) {
      Get.snackbar(
        'รหัสผ่านไม่ตรงกัน',
        'กรุณากรอกให้ตรงกัน',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // ✅ ตรวจว่า username มีอยู่แล้วใน "user" หรือ "rider" หรือไม่
      final userDoc = await db.collection('user').doc(username).get();
      final riderDoc = await db.collection('rider').doc(username).get();

      if (userDoc.exists || riderDoc.exists) {
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar(
          'ชื่อผู้ใช้งานซ้ำ',
          'ชื่อ "$username" ถูกใช้งานแล้ว กรุณาเลือกชื่ออื่น',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => isLoading = false);
        return; // ❌ หยุดการสมัคร
      }

      // ✅ เข้าสู่ขั้นตอนบันทึกปกติ
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      String? imageUrlSupabase;

      if (image != null) {
        final file = File(image!.path);
        final fileName =
            "user_images/${DateTime.now().millisecondsSinceEpoch}_${image!.name}";
        await Supabase.instance.client.storage
            .from('user')
            .upload(fileName, file);
        imageUrlSupabase = Supabase.instance.client.storage
            .from('user')
            .getPublicUrl(fileName);
      }

      final data = {
        "username": username,
        "phone": phone,
        "password": hashedPassword,
        "imageSupabase": imageUrlSupabase ?? "",
        "addresses": addresses,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await db.collection('user').doc(username).set(data);

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'สำเร็จ',
        'ลงทะเบียนเรียบร้อยแล้ว 🎉',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAll(() => const ULoginPage());
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'ผิดพลาด',
        'บันทึกข้อมูลไม่สำเร็จ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
