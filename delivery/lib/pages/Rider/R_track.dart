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
  DateTime? _lastUpdateTime; // ✅ ใช้กัน spam เขียน Firestore

  @override
  void initState() {
    super.initState();
    _trackLocationRealtime();
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

  // ✅ ติดตามตำแหน่งเรียลไทม์ พร้อมกรองและหน่วงเวลา
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
        accuracy: LocationAccuracy.medium, // ✅ ลด noise
        distanceFilter: 10, // ✅ อัปเดตเมื่อขยับเกิน 10 เมตร
      ),
    ).listen((Position position) {
      final now = DateTime.now();
      // ✅ เขียน Firestore แค่ทุก 5 วิ
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
        // ✅ ขยับกล้องแบบปลอดภัยใน flutter_map 4+
        mapController.mapEventStream.first.then((_) {
          mapController.move(
            LatLng(position.latitude, position.longitude),
            mapController.camera.zoom,
          );
        });
      }
    });
  }

  // ✅ อัปเดตสถานะสินค้า
  Future<void> _updateStatus(Map<String, dynamic> data) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId);

      int status = data["status"] ?? 2;
      int newStatus = status + 1;
      String? imageUrl;

      if (statusImage != null) {
        imageUrl = await _uploadImage(statusImage!, "status$newStatus");
      }

      final updateData = {"status": newStatus, "updatedAt": Timestamp.now()};

      if (imageUrl != null) {
        updateData["image_url_status$newStatus"] = imageUrl;
      }

      await docRef.update(updateData);

      if (newStatus >= 4) {
        Get.snackbar(
          "สำเร็จ",
          "อัปเดตสถานะเป็นส่งสำเร็จแล้ว!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAll(() => const RHomePage());
      } else {
        Get.snackbar(
          "สำเร็จ",
          "อัปเดตสถานะเป็น [$newStatus] แล้ว",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }

      setState(() {
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
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          final receiver = data["receiver_name"] ?? "-";
          final address = data["receiver_address"] ?? "-";
          final receiverLat = (data["receiver_lat"] ?? 0).toDouble();
          final receiverLng = (data["receiver_lng"] ?? 0).toDouble();
          final status = data["status"] ?? 1;

          String statusText = switch (status) {
            1 => "[1] รอไรเดอร์มารับสินค้า",
            2 => "[2] กำลังเดินทางไปรับของ",
            3 => "[3] กำลังนำส่งสินค้า",
            4 => "[4] ส่งสำเร็จแล้ว",
            _ => "ไม่ทราบสถานะ",
          };

          final riderLoc = data["rider_location"];
          LatLng riderPosition = riderLoc != null
              ? LatLng(riderLoc["lat"], riderLoc["lng"])
              : LatLng(13.736717, 100.523186);
          LatLng receiverPosition = LatLng(receiverLat, receiverLng);

          return Column(
            children: [
              // ✅ แผนที่เรียลไทม์
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
                        // จุดไรเดอร์
                        Marker(
                          point: riderPosition,
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        // จุดผู้รับ
                        Marker(
                          point: receiverPosition,
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

              // ✅ ข้อมูลและปุ่ม
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ผู้รับ: $receiver",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(address),
                    const SizedBox(height: 8),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
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
    );
  }
}
