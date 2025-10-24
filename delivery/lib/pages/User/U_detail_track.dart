import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UDetailTrackPage extends StatelessWidget {
  final String orderId;
  const UDetailTrackPage({super.key, required this.orderId});

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
          "ติดตามการส่งสินค้า",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      // ✅ ดึงข้อมูลออเดอร์แบบเรียลไทม์
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("ไม่พบข้อมูลออเดอร์นี้"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data["status"] ?? 1;

          // ✅ เลือกรูปตามสถานะ
          final imageUrl = switch (status) {
            1 => data["image_url"],
            2 => data["image_url"],
            3 => data["image_url_status3"],
            4 => data["image_url_status4"],
            _ => null,
          };

          // ✅ จุดพิกัด
          final double senderLat = (data["sender_lat"] ?? 0).toDouble();
          final double senderLng = (data["sender_lng"] ?? 0).toDouble();
          final double receiverLat = (data["receiver_lat"] ?? 0).toDouble();
          final double receiverLng = (data["receiver_lng"] ?? 0).toDouble();

          final LatLng senderPos = LatLng(senderLat, senderLng);
          final LatLng receiverPos = LatLng(receiverLat, receiverLng);

          // ✅ จุดเริ่มต้นไรเดอร์
          LatLng? riderPos;
          if (data["rider_location"] != null) {
            final loc = data["rider_location"];
            if (loc["lat"] != null && loc["lng"] != null) {
              riderPos = LatLng(
                (loc["lat"] ?? 0).toDouble(),
                (loc["lng"] ?? 0).toDouble(),
              );
            }
          }

          // ✅ เลือกเป้าหมายตามสถานะ
          // status 2 → จุดของผู้ส่ง
          // status 3 → จุดของผู้รับ
          LatLng targetPos = switch (status) {
            2 => senderPos,
            3 => receiverPos,
            _ => receiverPos,
          };

          // ✅ แสดง marker ตามสถานะ
          List<Marker> markers = [];

          // ไรเดอร์ (ถ้ามี)
          if (riderPos != null) {
            markers.add(
              Marker(
                point: riderPos,
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.blue,
                  size: 38,
                ),
              ),
            );
          }

          // เป้าหมาย (เปลี่ยนจุดตามสถานะ)
          markers.add(
            Marker(
              point: targetPos,
              child: Icon(
                Icons.location_on,
                color: status == 2 ? Colors.orange : Colors.red,
                size: 42,
              ),
            ),
          );

          // ✅ สินค้าในออเดอร์
          final List<dynamic> products = data["products"] ?? [];

          return Column(
            children: [
              // ✅ แถบสถานะ
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Text(
                        "$status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusText(status),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ รูปภาพสถานะ
              if (imageUrl != null && imageUrl.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text("ไม่มีภาพประกอบในสถานะนี้")),
                ),

              // ✅ แผนที่
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: riderPos ?? targetPos,
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

              // ✅ รายละเอียดไรเดอร์ + สินค้า
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ข้อมูลไรเดอร์ ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                data["rider_image_url"] != null &&
                                    data["rider_image_url"]
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(data["rider_image_url"])
                                : const AssetImage("assets/images/profile.png")
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("เบอร์โทร: ${data["rider_phone"] ?? "-"}"),
                                const SizedBox(height: 4),
                                Text(
                                  "ป้ายทะเบียน: ${data["vehicleController"] ?? data["vehicle_plate"] ?? "-"}",
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.directions_bike,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(thickness: 1),

                      // --- รายการสินค้า ---
                      const Text(
                        "รายการสินค้าในออเดอร์นี้:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (products.isNotEmpty)
                        ...products.map((item) {
                          final name = item["name"] ?? "-";
                          final qty = item["qty"] ?? "1";
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "$name",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Text(
                                  "x$qty",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      else
                        const Text("ไม่มีข้อมูลสินค้า"),
                    ],
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
