import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

      // ✅ ดึงออเดอร์ของผู้ใช้นี้ที่ "จัดส่งเสร็จแล้ว" (status = 4)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("receiver_name", isEqualTo: username)
            .where("status", isEqualTo: 4)
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

          // ✅ สร้าง Marker ของทุกไรเดอร์ที่จัดส่งเสร็จแล้ว
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;

            // --- Marker ของบ้านผู้รับ (ปลายทาง) ---
            if (data["receiver_lat"] != null && data["receiver_lng"] != null) {
              LatLng receiverHome = LatLng(
                (data["receiver_lat"] ?? 0).toDouble(),
                (data["receiver_lng"] ?? 0).toDouble(),
              );
              firstPos ??= receiverHome;
              markers.add(
                Marker(
                  point: receiverHome,
                  child: const Icon(Icons.home, size: 40, color: Colors.green),
                ),
              );
            }

            // --- Marker ของตำแหน่งสุดท้ายของไรเดอร์ (ตอนส่งสำเร็จ) ---
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
                    size: 38,
                    color: Colors.blue,
                  ),
                ),
              );
            }
          }

          return Column(
            children: [
              // ✅ รายการเลื่อนดูได้
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                            const SizedBox(height: 8),
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

                            const Divider(thickness: 1),
                          ],
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
