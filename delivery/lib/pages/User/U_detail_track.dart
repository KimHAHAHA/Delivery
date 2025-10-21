import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UDetailTrackPage extends StatelessWidget {
  final String orderId; // ✅ รับ orderId

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

      // ✅ Stream หลักสำหรับออเดอร์นี้
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

          // ✅ กำหนดเป้าหมายแผนที่ตามสถานะ
          final double targetLat = status == 2
              ? (data["sender_lat"] ?? 0).toDouble()
              : (data["receiver_lat"] ?? 0).toDouble();
          final double targetLng = status == 2
              ? (data["sender_lng"] ?? 0).toDouble()
              : (data["receiver_lng"] ?? 0).toDouble();

          LatLng targetPos = LatLng(targetLat, targetLng);

          return Column(
            children: [
              // ✅ แถบสถานะด้านบน
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

              // ✅ แผนที่ Real-time แสดงไรเดอร์และเป้าหมาย (sender/receiver)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("orders")
                      .where("status", isGreaterThanOrEqualTo: 2)
                      .where("status", isLessThanOrEqualTo: 3)
                      .snapshots(),
                  builder: (context, riderSnap) {
                    if (!riderSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final riderDocs = riderSnap.data!.docs;
                    final List<Marker> markers = [];

                    // ✅ Marker ของไรเดอร์ทั้งหมด
                    for (var doc in riderDocs) {
                      final rData = doc.data() as Map<String, dynamic>;
                      final loc = rData["rider_location"];
                      if (loc != null &&
                          loc["lat"] != null &&
                          loc["lng"] != null) {
                        markers.add(
                          Marker(
                            point: LatLng(
                              (loc["lat"] ?? 0).toDouble(),
                              (loc["lng"] ?? 0).toDouble(),
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.blue,
                              size: 38,
                            ),
                          ),
                        );
                      }
                    }

                    // ✅ Marker ของจุดเป้าหมาย (เปลี่ยนตามสถานะ)
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

                    return FlutterMap(
                      options: MapOptions(
                        initialCenter: targetPos,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    );
                  },
                ),
              ),

              // ✅ ข้อมูลไรเดอร์
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage:
                          data["rider_image_url"] != null &&
                              data["rider_image_url"].toString().isNotEmpty
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
                            "ป้ายทะเบียน: ${data["vehicleController"] ?? data["vehicle_plate"] ?? data["vehicle_number"] ?? "-"}",
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "สินค้า: ${data["products"] != null && data["products"].isNotEmpty ? data["products"][0]["name"] : "-"}",
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
              ),
            ],
          );
        },
      ),
    );
  }
}
