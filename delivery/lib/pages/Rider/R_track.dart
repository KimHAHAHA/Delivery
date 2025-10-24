import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider/R_home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RTrackPage extends StatefulWidget {
  final String orderId;

  const RTrackPage({super.key, required this.orderId});

  @override
  State<RTrackPage> createState() => _RTrackPageState();
}

class _RTrackPageState extends State<RTrackPage> {
  File? statusImage;
  bool isLoading = false;
  final MapController mapController = MapController();
  Position? currentPosition;
  DateTime? _lastUpdateTime;
  int currentStatus = 1; // ✅ เก็บสถานะปัจจุบัน

  @override
  void initState() {
    super.initState();
    _trackLocationRealtime();
  }

  // ✅ ป้องกันปุ่ม Back (จนกว่าจะส่งของสำเร็จ)
  Future<bool> _onWillPop() async {
    if (currentStatus < 4) {
      Get.snackbar(
        "ไม่สามารถออกได้",
        "กรุณาส่งสินค้าให้เสร็จก่อนออกจากหน้านี้",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false; // 🚫 ไม่อนุญาตให้ย้อนกลับ
    }
    return true; // ✅ อนุญาตเมื่อส่งสำเร็จ
  }

  // ✅ เลือกรูปจากกล้อง
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        statusImage = File(picked.path);
      });
    }
  }

  // ✅ อัปโหลดรูปไป Supabase
  Future<String?> _uploadImage(File file, String folder) async {
    try {
      final fileName = "${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await Supabase.instance.client.storage
          .from('order-status')
          .upload(fileName, file);

      return Supabase.instance.client.storage
          .from('order-status')
          .getPublicUrl(fileName);
    } catch (e) {
      Get.snackbar(
        "อัปโหลดล้มเหลว",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // ✅ ติดตามตำแหน่งไรเดอร์แบบเรียลไทม์
  Future<void> _trackLocationRealtime() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "ตำแหน่งปิดอยู่",
        "กรุณาเปิด GPS ก่อนใช้งาน",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar(
        "ไม่มีสิทธิ์เข้าถึงตำแหน่ง",
        "โปรดอนุญาตตำแหน่งให้แอป",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final now = DateTime.now();
      if (_lastUpdateTime == null ||
          now.difference(_lastUpdateTime!).inSeconds >= 5) {
        _lastUpdateTime = now;
        currentPosition = position;

        FirebaseFirestore.instance
            .collection("orders")
            .doc(widget.orderId)
            .update({
              "rider_location": {
                "lat": position.latitude,
                "lng": position.longitude,
              },
            });

        mapController.move(
          LatLng(position.latitude, position.longitude),
          mapController.camera.zoom,
        );
      }
    });
  }

  // ✅ อัปเดตสถานะการจัดส่ง
  // ✅ อัปเดตสถานะการจัดส่ง
  Future<void> _updateStatus(Map<String, dynamic> data) async {
    if (isLoading) return;

    // ✅ บังคับให้ถ่ายภาพก่อนอัปเดตสถานะ
    if (statusImage == null) {
      Get.snackbar(
        "กรุณาถ่ายภาพก่อน",
        "ต้องแนบรูปภาพประกอบก่อนอัปเดตสถานะถัดไป",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId);

      int status = data["status"] ?? 2;
      int newStatus = status + 1;
      String? imageUrl;

      // ✅ อัปโหลดรูปก่อนอัปเดตสถานะ
      if (statusImage != null) {
        imageUrl = await _uploadImage(statusImage!, "status$newStatus");
      }

      final updateData = {"status": newStatus, "updatedAt": Timestamp.now()};
      if (imageUrl != null) {
        updateData["image_url_status$newStatus"] = imageUrl;
      }

      await docRef.update(updateData);

      String message = switch (newStatus) {
        2 => "กำลังไปรับของจากผู้ส่ง...",
        3 => "รับของแล้ว กำลังจัดส่งให้ผู้รับ...",
        4 => "ส่งสำเร็จแล้ว! 🎉",
        _ => "อัปเดตสถานะเรียบร้อย",
      };

      Get.snackbar(
        "สำเร็จ",
        message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      if (newStatus >= 4) {
        await Future.delayed(const Duration(seconds: 1));
        Get.offAll(() => const RHomePage());
      }

      setState(() {
        currentStatus = newStatus;
        statusImage = null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถอัปเดตสถานะได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 🚫 ปิดปุ่ม Back
      child: Scaffold(
        backgroundColor: const Color(0xFF7DE1A4),
        appBar: AppBar(
          automaticallyImplyLeading: false, // 🚫 ปิดปุ่มย้อนกลับบน AppBar
          backgroundColor: const Color(0xFF7DE1A4),
          elevation: 0,
          title: const Text(
            "ติดตามการส่ง",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("orders")
              .doc(widget.orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("ไม่พบข้อมูลออเดอร์นี้"));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentStatus = data["status"] ?? 1;

            final status = currentStatus;
            final targetLat = status == 2
                ? (data["sender_lat"] ?? 0).toDouble()
                : (data["receiver_lat"] ?? 0).toDouble();
            final targetLng = status == 2
                ? (data["sender_lng"] ?? 0).toDouble()
                : (data["receiver_lng"] ?? 0).toDouble();
            final targetName = status == 2
                ? data["sender_name"] ?? "-"
                : data["receiver_name"];
            final targetAddress = status == 2
                ? data["sender_address"] ?? "-"
                : data["receiver_address"];

            LatLng targetPosition = LatLng(targetLat, targetLng);
            final riderLoc = data["rider_location"];
            LatLng riderPosition = riderLoc != null
                ? LatLng(riderLoc["lat"], riderLoc["lng"])
                : LatLng(13.736717, 100.523186);

            String statusText = switch (status) {
              1 => "[1] รอไรเดอร์มารับสินค้า",
              2 => "[2] กำลังเดินทางไปรับของจากผู้ส่ง",
              3 => "[3] กำลังนำส่งสินค้าให้ผู้รับ",
              4 => "[4] ส่งสำเร็จแล้ว",
              _ => "ไม่ทราบสถานะ",
            };

            return Column(
              children: [
                // ✅ แผนที่
                Expanded(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: riderPosition,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                        userAgentPackageName: 'net.delivery.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: riderPosition,
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          Marker(
                            point: targetPosition,
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

                // ✅ ข้อมูลปลายทาง + ปุ่มอัปเดต
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🏠 ต้นทางผู้ส่ง
                      const Text(
                        "ต้นทาง (ผู้ส่ง):",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text("ชื่อ: ${data["sender_name"] ?? "-"}"),
                      Text("เบอร์โทร: ${data["sender_phone"] ?? "-"}"),
                      const SizedBox(height: 12),

                      // 🎯 ปลายทางผู้รับ
                      const Text(
                        "ปลายทาง (ผู้รับ):",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text("ชื่อ: ${data["receiver_name"] ?? "-"}"),
                      Text("เบอร์โทร: ${data["receiver_phone"] ?? "-"}"),
                      const SizedBox(height: 8),

                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 📷 ถ่ายภาพสถานะ
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: statusImage == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text("แตะเพื่อถ่ายภาพประกอบสถานะ"),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    statusImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔘 ปุ่มอัปเดตสถานะ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status >= 4
                                ? Colors.grey
                                : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: status >= 4
                              ? null
                              : () => _updateStatus(data),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  "อัปเดตสถานะ",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
