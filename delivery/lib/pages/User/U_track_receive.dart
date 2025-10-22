import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UTrackReceive extends StatelessWidget {
  final String username; // ✅ รับชื่อผู้ใช้ (เจ้าของสินค้าที่รอให้มารับ)
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
          "ติดตามการรับสินค้า",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      // ✅ ดึงออเดอร์ทั้งหมดของผู้ใช้นี้ที่อยู่ในสถานะ "รอรับสินค้า"
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("sender_username", isEqualTo: username)
            .where("status", isEqualTo: 2) // 2 = กำลังมารับสินค้า
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(
              child: Text("ยังไม่มีไรเดอร์ที่กำลังมารับสินค้า"),
            );
          }

          List<Marker> markers = [];
          LatLng? firstPos;

          // ✅ สร้าง Marker ของทุกไรเดอร์
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;

            // --- Marker ของไรเดอร์ ---
            final riderLoc = data["rider_location"];
            if (riderLoc != null &&
                riderLoc["lat"] != null &&
                riderLoc["lng"] != null) {
              LatLng pos = LatLng(
                (riderLoc["lat"] ?? 0).toDouble(),
                (riderLoc["lng"] ?? 0).toDouble(),
              );
              firstPos ??= pos;
              markers.add(
                Marker(
                  point: pos,
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 38,
                    color: Colors.blue,
                  ),
                ),
              );
            }

            // --- Marker ของผู้ใช้ (บ้านต้นทาง) ---
            if (data["sender_lat"] != null && data["sender_lng"] != null) {
              LatLng senderHome = LatLng(
                (data["sender_lat"] ?? 0).toDouble(),
                (data["sender_lng"] ?? 0).toDouble(),
              );
              markers.add(
                Marker(
                  point: senderHome,
                  child: const Icon(Icons.home, size: 40, color: Colors.orange),
                ),
              );
            }
          }

          return Column(
            children: [
              // ✅ แผนที่แสดงไรเดอร์ที่กำลังมารับสินค้า
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        firstPos ?? const LatLng(13.736717, 100.523186),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),

              // ✅ แสดงข้อมูลไรเดอร์ทั้งหมดที่มารับสินค้า
              Container(
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
                    return Column(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    "หมายเลขพัสดุ: ${data["order_code"] ?? "-"}",
                                  ),
                                  Text(
                                    "สินค้า: ${data["products"]?[0]?["name"] ?? "-"}",
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.directions_bike,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                        const Divider(thickness: 1),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
