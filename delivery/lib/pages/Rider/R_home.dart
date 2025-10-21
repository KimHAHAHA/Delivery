import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:delivery/pages/Rider/R_track.dart';
import 'package:delivery/providers/rider_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class RHomePage extends StatefulWidget {
  const RHomePage({super.key});

  @override
  State<RHomePage> createState() => _RHomePageState();
}

class _RHomePageState extends State<RHomePage> {
  int _selectedIndex = 0;
  Position? currentPosition;
  bool isAccepting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  // ✅ ดึงพิกัดปัจจุบันของไรเดอร์
  Future<void> _getCurrentPosition() async {
    try {
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
          "ไม่มีสิทธิ์เข้าถึง GPS",
          "โปรดอนุญาตตำแหน่งให้แอป",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
    }
  }

  // ✅ แถบล่างเปลี่ยนหน้า
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Get.off(() => const RHomePage());
    } else {
      Get.to(() => const RProfilePage());
    }
  }

  // ✅ คำนวณระยะทางจากตำแหน่งปัจจุบัน
  String _distanceText(double lat, double lng) {
    if (currentPosition == null) return "";
    final distance = const Distance().as(
      LengthUnit.Meter,
      LatLng(currentPosition!.latitude, currentPosition!.longitude),
      LatLng(lat, lng),
    );
    if (distance > 1000) {
      return "${(distance / 1000).toStringAsFixed(2)} กม.";
    }
    return "${distance.toStringAsFixed(0)} เมตร";
  }

  // ✅ ฟังก์ชันรับงาน (Transaction ป้องกันแย่งงาน)
  Future<void> _acceptJob(
    String orderId,
    Map<String, dynamic> orderData,
    RiderProvider rider,
  ) async {
    if (isAccepting) return;
    isAccepting = true;

    // ✅ ตรวจพิกัดผู้ส่ง
    final senderLat = (orderData["sender_lat"] ?? 0).toDouble();
    final senderLng = (orderData["sender_lng"] ?? 0).toDouble();

    if (currentPosition == null) {
      Get.snackbar(
        "ไม่สามารถรับงานได้",
        "ไม่พบตำแหน่งปัจจุบันของคุณ",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isAccepting = false;
      return;
    }

    // ✅ คำนวณระยะทางจากไรเดอร์ → ผู้ส่ง
    final distance = const Distance().as(
      LengthUnit.Meter,
      LatLng(currentPosition!.latitude, currentPosition!.longitude),
      LatLng(senderLat, senderLng),
    );

    // ✅ บังคับให้อยู่ใกล้ผู้ส่งไม่เกิน 20 เมตรถึงจะรับได้
    if (distance > 20) {
      Get.snackbar(
        "อยู่ไกลจากจุดรับของเกินไป",
        "ต้องอยู่ในระยะไม่เกิน 20 เมตรถึงจะรับงานได้ (ตอนนี้ ${distance.toStringAsFixed(0)} เมตร)",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      isAccepting = false;
      return;
    }

    // ✅ ถ้าผ่านเงื่อนไข → ดำเนินการรับงานปกติ
    final ref = FirebaseFirestore.instance.collection('orders').doc(orderId);
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw "ไม่พบออเดอร์นี้";

        final data = snap.data() as Map<String, dynamic>;
        if (data['status'] != 1 || data['rider_id'] != null) {
          throw "งานนี้มีไรเดอร์รับไปแล้ว";
        }

        tx.update(ref, {
          "status": 2,
          "rider_id": rider.uid,
          "rider_name": rider.username,
          "rider_phone": rider.phone,
          "rider_image_url": rider.riderImageUrl ?? "",
          "rider_location": {
            "lat": currentPosition?.latitude ?? 0,
            "lng": currentPosition?.longitude ?? 0,
          },
          "acceptedAt": FieldValue.serverTimestamp(),
        });
      });

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "✅ สำเร็จ",
        "รับงานเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Get.to(() => RTrackPage(orderId: orderId));
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "ผิดพลาด",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAccepting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = context.watch<RiderProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        title: const Text(
          "งานที่รอรับ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("status", isEqualTo: 1)
            .where("rider_id", isNull: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "ยังไม่มีงานรอรับ",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final doc = jobs[index];
              final data = doc.data() as Map<String, dynamic>;

              final sender = data["sender_name"] ?? "-";
              final address = data["sender_address"] ?? "-";
              final lat = (data["sender_lat"] ?? 0).toDouble();
              final lng = (data["sender_lng"] ?? 0).toDouble();
              final imageUrl =
                  data["image_url_status1"] ?? data["image_url"] ?? "";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ รูปสินค้า
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.inventory,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sender,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              if (lat != 0 &&
                                  lng != 0 &&
                                  currentPosition != null)
                                Text(
                                  "ระยะห่าง: ${_distanceText(lat, lng)}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ ปุ่มรับงาน
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () =>
                            _acceptJob(doc.id, data, riderProvider),
                        child: const Text(
                          "รับงาน",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }
}
