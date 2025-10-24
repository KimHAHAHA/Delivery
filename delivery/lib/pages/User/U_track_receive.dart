import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_detail_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class UTrackReceive extends StatelessWidget {
  final String username; // ✅ ชื่อผู้ใช้ (ผู้รับ)
  const UTrackReceive({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "สินค้าที่จัดส่งสำเร็จแล้ว",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      // ✅ ดึงออเดอร์ของผู้ใช้นี้ (เป็นผู้รับหรือผู้ส่ง) ที่จัดส่งสำเร็จ
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("status", isEqualTo: 4)
            .where(
              Filter.or(
                Filter("receiver_name", isEqualTo: username),
                Filter("sender_name", isEqualTo: username),
              ),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "ยังไม่มีสินค้าที่จัดส่งสำเร็จแล้ว",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          List<Marker> markers = [];
          LatLng? firstPos;

          // ✅ สร้าง Marker ของแต่ละออเดอร์ (บ้านผู้รับ + ไรเดอร์)
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;

            // --- Marker ของบ้านผู้รับ ---
            if (data["receiver_lat"] != null && data["receiver_lng"] != null) {
              LatLng receiverHome = LatLng(
                (data["receiver_lat"] ?? 0).toDouble(),
                (data["receiver_lng"] ?? 0).toDouble(),
              );
              firstPos ??= receiverHome;
              markers.add(
                Marker(
                  point: receiverHome,
                  child: const Icon(Icons.home, size: 38, color: Colors.green),
                ),
              );
            }

            // --- Marker ของตำแหน่งสุดท้ายของไรเดอร์ ---
            final riderLoc = data["rider_location"];
            if (riderLoc != null &&
                riderLoc["lat"] != null &&
                riderLoc["lng"] != null) {
              LatLng riderPos = LatLng(
                (riderLoc["lat"] ?? 0).toDouble(),
                (riderLoc["lng"] ?? 0).toDouble(),
              );
              markers.add(
                Marker(
                  point: riderPos,
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 36,
                    color: Colors.blue,
                  ),
                ),
              );
            }
          }

          return Column(
            children: [
              // ✅ รายการสินค้า
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: orders.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final List<dynamic> products = data["products"] ?? [];
                        final isSender = data["sender_name"] == username;
                        final isReceiver = data["receiver_name"] == username;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ ข้อมูลไรเดอร์
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        data["rider_image_url"] != null &&
                                            data["rider_image_url"]
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(data["rider_image_url"])
                                        : const AssetImage(
                                                "assets/images/profile.png",
                                              )
                                              as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ชื่อไรเดอร์: ${data["rider_name"] ?? "-"}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "เบอร์โทร: ${data["rider_phone"] ?? "-"}",
                                        ),
                                        Text(
                                          "สถานะ: จัดส่งสำเร็จแล้ว",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // ✅ แสดงว่าเป็นออเดอร์ฝั่งไหน
                              Text(
                                isSender
                                    ? "📦 ประเภท: ผู้ส่ง"
                                    : isReceiver
                                    ? "📬 ประเภท: ผู้รับ"
                                    : "ไม่ระบุ",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ✅ รายการสินค้า
                              const Text(
                                "รายการสินค้า:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              ...products.map((p) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(p["name"] ?? "-"),
                                      Text("x${p["qty"] ?? "-"}"),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 8),

                              // ✅ ปุ่มดูรายละเอียด
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    Get.to(
                                      () => UDetailTrackPage(orderId: doc.id),
                                    );
                                  },
                                  child: const Text("ดูรายละเอียด"),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
