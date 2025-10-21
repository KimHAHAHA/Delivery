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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ติดตามการส่ง",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("ไม่พบข้อมูลออเดอร์นี้"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data["status"] ?? 1;

          final riderLoc = data["rider_location"];
          final receiverLat = (data["receiver_lat"] ?? 0).toDouble();
          final receiverLng = (data["receiver_lng"] ?? 0).toDouble();

          // ✅ พิกัดของผู้รับ
          LatLng receiverPos = LatLng(receiverLat, receiverLng);

          // ✅ พิกัดของไรเดอร์ (อาจเป็น null ตอนยังไม่รับงาน)
          LatLng? riderPos = riderLoc != null
              ? LatLng(
                  (riderLoc["lat"] ?? 0).toDouble(),
                  (riderLoc["lng"] ?? 0).toDouble(),
                )
              : null;

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

              // ✅ แผนที่เรียลไทม์
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: riderPos ?? receiverPos,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                      userAgentPackageName: 'net.delivery.user',
                    ),
                    MarkerLayer(
                      markers: [
                        // จุดไรเดอร์
                        if (riderPos != null)
                          Marker(
                            point: riderPos,
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        // จุดผู้รับ
                        Marker(
                          point: receiverPos,
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
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage("assets/images/profile.png"),
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
                            "บ้ายทะเบียน: ${data["vehicleController"] ?? "-"}",
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
