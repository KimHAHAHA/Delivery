import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_detail_track.dart';
import 'package:delivery/pages/User/U_track_receive.dart';
import 'package:delivery/pages/User/๊๊U_track_send.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UTrackPage extends StatelessWidget {
  const UTrackPage({super.key});

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
    // ✅ สมมติชื่อผู้ใช้ (ในจริงควรได้จากระบบ login)
    const String username = "user";

    // ✅ Stream ดึงออเดอร์ที่เราเป็น “ผู้ส่ง”
    final sendStream = FirebaseFirestore.instance
        .collection("orders")
        .where("sender_name", isEqualTo: username)
        .where("status", whereIn: [1, 2, 3])
        .snapshots();

    // ✅ Stream ดึงออเดอร์ที่เราเป็น “ผู้รับ”
    final receiveStream = FirebaseFirestore.instance
        .collection("orders")
        .where("receiver_name", isEqualTo: username)
        .where("status", whereIn: [1, 2, 3])
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        title: const Text(
          "ติดตามของฉันทั้งหมด",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // ✅ รวมทั้ง 2 stream เข้าด้วยกัน
      body: StreamBuilder<QuerySnapshot>(
        stream: sendStream,
        builder: (context, sendSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: receiveStream,
            builder: (context, recvSnap) {
              if (sendSnap.connectionState == ConnectionState.waiting ||
                  recvSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sendOrders = sendSnap.data?.docs ?? [];
              final recvOrders = recvSnap.data?.docs ?? [];

              // ✅ รวมออเดอร์ที่เป็นของเรา (ส่ง + รับ)
              final allOrders = [...sendOrders, ...recvOrders];

              // ✅ ลบรายการซ้ำ (กรณีเราเป็นทั้งผู้ส่งและผู้รับ)
              final uniqueOrders = {
                for (var doc in allOrders) doc.id: doc,
              }.values.toList();

              if (uniqueOrders.isEmpty) {
                return const Center(
                  child: Text(
                    "ยังไม่มีออเดอร์ที่เกี่ยวข้องกับคุณ",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              }

              // ✅ แสดงรายการทั้งหมด
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: uniqueOrders.length,
                itemBuilder: (context, index) {
                  final order =
                      uniqueOrders[index].data() as Map<String, dynamic>;
                  final orderId = uniqueOrders[index].id;
                  final riderName = order["rider_name"] ?? "ยังไม่มีไรเดอร์";
                  final riderPhone = order["rider_phone"] ?? "-";
                  final status = order["status"] ?? 1;
                  final imageUrl = order["image_url"] ?? "";
                  final isSender = order["sender_name"] == username;
                  final isReceiver = order["receiver_name"] == username;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ รูปภาพสินค้า
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            image: imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl.isEmpty
                              ? const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // ✅ ข้อมูลออเดอร์
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ชื่อไรเดอร์: $riderName",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "เบอร์โทร: $riderPhone",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                isSender
                                    ? "ประเภท: ผู้ส่ง"
                                    : isReceiver
                                    ? "ประเภท: ผู้รับ"
                                    : "ไม่ระบุ",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    "สถานะ: ",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    _statusText(status),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

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
                                      () => UDetailTrackPage(orderId: orderId),
                                    );
                                  },
                                  child: const Text("รายละเอียด"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // ✅ ปุ่มด้านล่าง
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: const Color(0xFF7DE1A4),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => UTrackSend(username: username));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("ติดตามการส่ง"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => UTrackReceive(username: username));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("ติดตามการรับ"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
