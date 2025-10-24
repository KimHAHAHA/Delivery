import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_detail_track.dart';
import 'package:delivery/pages/User/U_track_receive.dart';
import 'package:delivery/pages/User/๊๊U_track_send.dart';
import 'package:delivery/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class UTrackPage extends StatefulWidget {
  const UTrackPage({super.key});

  @override
  State<UTrackPage> createState() => _UTrackPageState();
}

class _UTrackPageState extends State<UTrackPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Widget _buildOrderList(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "ยังไม่มีออเดอร์ในหมวดนี้",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            final riderName = order["rider_name"] ?? "ยังไม่มีไรเดอร์";
            final riderPhone = order["rider_phone"] ?? "-";
            final status = order["status"] ?? 1;
            final imageUrl = order["image_url"] ?? "";

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
                  // ✅ รูปสินค้า
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
                        Row(
                          children: [
                            const Text("สถานะ: "),
                            Text(
                              _statusText(status),
                              style: TextStyle(
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
                              Get.to(() => UDetailTrackPage(orderId: orderId));
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
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final username = userProvider.username;

    if (username == null || username.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("⚠️ กรุณาเข้าสู่ระบบใหม่อีกครั้ง")),
      );
    }

    print("👤 current username (from Provider): $username");

    final sendStream = FirebaseFirestore.instance
        .collection("orders")
        .where("sender_name", isEqualTo: username)
        .where("status", whereIn: [1, 2, 3])
        .snapshots();

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
          "ติดตามของฉัน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: "📦 ที่ฉันส่ง"),
            Tab(text: "📬 ที่ฉันรับ"),
          ],
        ),
      ),

      // ✅ แสดงแต่ละแท็บ
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrderList(sendStream), _buildOrderList(receiveStream)],
      ),

      // ✅ ปุ่มล่าง
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: const Color(0xFF7DE1A4),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => const UTrackSend());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("ดูแผนที่การส่ง"),
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
                child: const Text("สินค้าที่ได้รับสำเร็จ"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
