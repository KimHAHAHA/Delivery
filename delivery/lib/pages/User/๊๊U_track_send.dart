import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class UTrackSend extends StatelessWidget {
  UTrackSend({super.key});

  // ✅ ข้อความสถานะ
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

  // ✅ สีสถานะ
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

  // ✅ สีของไรเดอร์แต่ละคน
  final List<Color> riderColors = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.amber,
    Colors.tealAccent,
    Colors.limeAccent,
  ];

  @override
  Widget build(BuildContext context) {
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

      // ✅ ดึงข้อมูลออเดอร์ทั้งหมดของผู้ใช้
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("sender_name", isEqualTo: username)
            .where("status", whereIn: [2, 3])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("ยังไม่มีไรเดอร์ที่กำลังจัดส่งสินค้าของคุณ"),
            );
          }

          List<Marker> markers = [];
          LatLng? firstPos;

          for (int i = 0; i < orders.length; i++) {
            final doc = orders[i];
            final data = doc.data() as Map<String, dynamic>;
            final status = data["status"] ?? 0;
            final Color riderColor = riderColors[i % riderColors.length];

            final riderLoc = data["rider_location"];
            final double senderLat = (data["sender_lat"] ?? 0).toDouble();
            final double senderLng = (data["sender_lng"] ?? 0).toDouble();
            final double receiverLat = (data["receiver_lat"] ?? 0).toDouble();
            final double receiverLng = (data["receiver_lng"] ?? 0).toDouble();

            final LatLng senderPos = LatLng(senderLat, senderLng);
            final LatLng receiverPos = LatLng(receiverLat, receiverLng);

            LatLng? riderPos;
            if (riderLoc != null &&
                riderLoc["lat"] != null &&
                riderLoc["lng"] != null) {
              riderPos = LatLng(
                (riderLoc["lat"] ?? 0).toDouble(),
                (riderLoc["lng"] ?? 0).toDouble(),
              );
              firstPos ??= riderPos;
            }

            LatLng targetPos = switch (status) {
              2 => senderPos,
              3 => receiverPos,
              _ => receiverPos,
            };

            // ✅ Marker ไรเดอร์ (เปลี่ยนจากข้อความแดงเป็นชื่อไรเดอร์)
            if (riderPos != null) {
              markers.add(
                Marker(
                  point: riderPos,
                  width: 80,
                  height: 60,
                  child: Column(
                    children: [
                      Icon(Icons.delivery_dining, color: riderColor, size: 36),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          data["rider_name"] ?? "ไรเดอร์",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: riderColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ✅ Marker จุดหมาย
            markers.add(
              Marker(
                point: targetPos,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_on,
                  color: status == 2 ? Colors.orange : Colors.red,
                  size: 40,
                ),
              ),
            );
          }

          return Stack(
            children: [
              // 🗺️ แผนที่
              FlutterMap(
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

              // ✅ Bottom Sheet (เลื่อนดูรายละเอียดได้)
              DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.2,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 60,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const Text(
                            "รายละเอียดไรเดอร์ที่กำลังจัดส่ง",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(thickness: 1),
                          ...orders.asMap().entries.map((entry) {
                            final i = entry.key;
                            final doc = entry.value;
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data["status"] ?? 0;
                            final imageUrl = data["rider_image_url"];
                            final riderColor =
                                riderColors[i % riderColors.length];
                            final List<dynamic> products =
                                data["products"] ?? [];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: riderColor,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "ชื่อไรเดอร์: ${data["rider_name"] ?? "-"}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: riderColor,
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
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.delivery_dining,
                                        color: riderColor,
                                        size: 28,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  const Text(
                                    "🛍️ รายการสินค้า:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // ✅ แสดงสินค้า
                                  if (products.isNotEmpty)
                                    Column(
                                      children: products.map((p) {
                                        final name = p["name"] ?? "-";
                                        final qtyRaw = p["qty"];

                                        final qty = (qtyRaw is String)
                                            ? int.tryParse(qtyRaw) ?? 1
                                            : (qtyRaw is num
                                                  ? qtyRaw.toInt()
                                                  : 1);

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    Text("จำนวน: $qty ชิ้น"),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  else
                                    const Text("ไม่มีข้อมูลสินค้า"),
                                  const Divider(thickness: 1),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
