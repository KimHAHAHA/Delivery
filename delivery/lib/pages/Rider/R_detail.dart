import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider/R_home.dart';
import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:delivery/pages/Rider/R_track.dart';
import 'package:delivery/providers/rider_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class RDetailPage extends StatefulWidget {
  final String orderId;

  const RDetailPage({super.key, required this.orderId});

  @override
  State<RDetailPage> createState() => _RDetailPageState();
}

class _RDetailPageState extends State<RDetailPage> {
  int _selectedIndex = 0;
  bool isLoading = false;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Get.offAll(() => const RHomePage());
    } else {
      Get.to(() => const RProfilePage());
    }
  }

  // ✅ ฟังก์ชันรับงาน
  Future<void> _acceptJob(Map<String, dynamic> data) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final rider = context.read<RiderProvider>();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      // อัปเดตสถานะและข้อมูลไรเดอร์
      await docRef.update({
        'status': 2, // [2] ไรเดอร์รับงาน
        'rider_id': rider.uid,
        'rider_name': rider.username,
        'rider_phone': rider.phone,
        'acceptedAt': Timestamp.now(),
      });

      Get.snackbar(
        "สำเร็จ",
        "คุณรับงานนี้เรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // ไปหน้า TrackPage
      Get.off(() => RTrackPage(orderId: widget.orderId));
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถรับงานได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        title: const Text(
          "รายละเอียดสินค้า",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      // ✅ ใช้ StreamBuilder ดึงข้อมูล order แบบเรียลไทม์
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("ไม่พบข้อมูลคำสั่งซื้อ"));
          }

          final products = data["products"] ?? [];
          final senderName = data["sender_name"] ?? "-";
          final senderPhone = data["sender_phone"] ?? "-";
          final receiverName = data["receiver_name"] ?? "-";
          final receiverPhone = data["receiver_phone"] ?? "-";
          final address = data["receiver_address"] ?? "-";
          final imageUrl = data["image_url"] ?? "";

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 50),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "ผู้ส่ง: $senderName",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("เบอร์: $senderPhone"),
                      const SizedBox(height: 8),

                      Text(
                        "ผู้รับ: $receiverName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("เบอร์: $receiverPhone"),
                      const SizedBox(height: 8),

                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.pink, size: 18),
                          SizedBox(width: 6),
                          Text("สถานที่ส่งสินค้า"),
                        ],
                      ),
                      Text(address),
                      const SizedBox(height: 16),

                      const Text(
                        "รายการสินค้า",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ...products.map(
                        (p) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p["name"] ?? "-"),
                            Text(p["qty"].toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ ปุ่มรับงาน
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : () => _acceptJob(data),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            "รับงาน",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ✅ Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }
}
