import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class UTrackSend extends StatelessWidget {
  const UTrackSend({super.key});

  String _statusText(int status) {
    switch (status) {
      case 1:
        return "รอไรเดอร์รับสินค้า";
      case 2:
        return "กำลังเดินทางมารับสินค้า";
      case 3:
        return "ไรเดอร์รับสินค้าแล้ว กำลังจัดส่ง";
      case 4:
        return "จัดส่งสำเร็จ";
      default:
        return "ไม่ทราบสถานะ";
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ดึง username จาก Provider (แทนการรับจาก constructor)
    final userProvider = context.watch<UserProvider>();
    final username = userProvider.username;

    if (username == null || username.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF7DE1A4),
        body: Center(
          child: Text(
            "⚠️ กรุณาเข้าสู่ระบบก่อนดูข้อมูลการจัดส่ง",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    print("👤 Current sender (from Provider): $username");

    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ติดตามไรเดอร์ทั้งหมดของฉัน",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      // ✅ ดึงออเดอร์เฉพาะของ user ที่เป็นผู้ส่ง
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("sender_name", isEqualTo: username) // 🔹 ดึงเฉพาะของเรา
            .where("status", whereIn: [2, 3]) // 🔹 กำลังมารับหรือจัดส่ง
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;
          print(
            "📦 พบออเดอร์ทั้งหมด ${orders.length} รายการของผู้ใช้ $username",
          );

          if (orders.isEmpty) {
            return const Center(
              child: Text("ยังไม่มีไรเดอร์ที่กำลังจัดส่งสินค้าของคุณ"),
            );
          }

          // ✅ สร้าง Marker ทั้งหมด
          List<Marker> markers = [];
          LatLng? firstPos;

          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            print(
              "🗺️ ตรวจข้อมูลออเดอร์: ${doc.id} | status=${data["status"]}",
            );

            // ✅ Marker ของไรเดอร์
            final riderLoc = data["rider_location"];
            if (riderLoc != null &&
                riderLoc["lat"] != null &&
                riderLoc["lng"] != null) {
              LatLng riderPos = LatLng(
                (riderLoc["lat"] ?? 0).toDouble(),
                (riderLoc["lng"] ?? 0).toDouble(),
              );
              firstPos ??= riderPos;
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

            // ✅ Marker ของผู้รับ
            if (data["receiver_lat"] != null && data["receiver_lng"] != null) {
              LatLng recvPos = LatLng(
                (data["receiver_lat"] ?? 0).toDouble(),
                (data["receiver_lng"] ?? 0).toDouble(),
              );
              markers.add(
                Marker(
                  point: recvPos,
                  child: const Icon(
                    Icons.location_on,
                    size: 42,
                    color: Colors.red,
                  ),
                ),
              );
            }
          }

          // ✅ UI รวม
          return Column(
            children: [
              // 🔹 แผนที่แสดงตำแหน่งไรเดอร์ทั้งหมด
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

              // 🔹 รายละเอียดไรเดอร์แต่ละคน
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
                  children: [
                    const Text(
                      "รายละเอียดไรเดอร์ที่กำลังจัดส่ง",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(thickness: 1),
                    ...orders.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data["status"] ?? 0;
                      final imageUrl = data["rider_image_url"];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  (imageUrl != null &&
                                      imageUrl.toString().isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage(
                                          "assets/images/profile.png",
                                        )
                                        as ImageProvider,
                            ),
                            const SizedBox(width: 12),
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
                                    "ป้ายทะเบียน: ${data["vehicleController"] ?? data["vehicle_plate"] ?? "-"}",
                                  ),
                                  Text(
                                    "สถานะ: ${_statusText(status)}",
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (data["products"] != null)
                                    Text(
                                      "สินค้า: ${(data["products"] as List).map((p) => p["name"]).join(', ')}",
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.delivery_dining,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
