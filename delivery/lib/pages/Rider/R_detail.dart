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

      await docRef.update({
        'status': 2,
        'rider_id': rider.uid,
        'rider_name': rider.username,
        "vehicleController": rider.vehicleController ?? "-",
        'rider_phone': rider.phone,
        'acceptedAt': Timestamp.now(),
      });

      Get.snackbar(
        "✅ รับงานสำเร็จ",
        "คุณได้รับงานนี้เรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.off(() => RTrackPage(orderId: widget.orderId));
    } catch (e) {
      Get.snackbar(
        "❌ ผิดพลาด",
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
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Get.back(), // ✅ กลับหน้าก่อนหน้า
        ),
        title: const Text(
          "รายละเอียดงานจัดส่ง",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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
                      // ✅ รูปสินค้า
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 20),

                      // ✅ ข้อมูลผู้ส่ง
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ข้อมูลผู้ส่ง",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("ชื่อ: $senderName"),
                              Text("เบอร์: $senderPhone"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✅ ข้อมูลผู้รับ
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ข้อมูลผู้รับ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("ชื่อ: $receiverName"),
                              Text("เบอร์: $receiverPhone"),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "ที่อยู่จัดส่ง",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(address),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✅ รายการสินค้า
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "รายการสินค้า",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const Divider(),
                              if (products.isEmpty)
                                const Text("- ไม่มีข้อมูลสินค้า -")
                              else
                                ...products.map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p["name"] ?? "-"),
                                        Text(
                                          "${p["qty"] ?? 1} ชิ้น",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ ปุ่มรับงาน
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: Colors.white,
                          ),
                    onPressed: isLoading ? null : () => _acceptJob(data),
                    label: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            "รับงานนี้",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
