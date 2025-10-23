import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider/R_home.dart';
import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:delivery/pages/Rider/R_track.dart';
import 'package:delivery/providers/rider_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class RDetailPage extends StatefulWidget {
  final String orderId;
  const RDetailPage({super.key, required this.orderId});

  @override
  State<RDetailPage> createState() => _RDetailPageState();
}

class _RDetailPageState extends State<RDetailPage> {
  int _selectedIndex = 0;
  bool isAccepting = false;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _updateCurrentPosition();
  }

  Future<void> _updateCurrentPosition() async {
    try {
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถดึงตำแหน่งได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Get.offAll(() => const RHomePage());
    } else {
      Get.to(() => const RProfilePage());
    }
  }

  /// ✅ ฟังก์ชันรับงาน
  Future<void> _acceptJob(
    String orderId,
    Map<String, dynamic> orderData,
    RiderProvider rider,
  ) async {
    if (isAccepting) return;
    isAccepting = true;

    try {
      currentPosition ??= await Geolocator.getCurrentPosition();

      final senderLat = (orderData["sender_lat"] ?? 0).toDouble();
      final senderLng = (orderData["sender_lng"] ?? 0).toDouble();

      if (currentPosition == null) {
        Get.snackbar(
          "ไม่สามารถรับงานได้",
          "ไม่พบตำแหน่งปัจจุบันของคุณ",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isAccepting = false;
        return;
      }

      final distance = const Distance().as(
        LengthUnit.Meter,
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        LatLng(senderLat, senderLng),
      );

      if (distance > 20) {
        Get.snackbar(
          "อยู่ไกลจากจุดรับของเกินไป",
          "ต้องอยู่ในระยะไม่เกิน 20 เมตรถึงจะรับงานได้ (ตอนนี้ ${distance.toStringAsFixed(0)} เมตร)",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        isAccepting = false;
        return;
      }

      final ref = FirebaseFirestore.instance.collection('orders').doc(orderId);
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw "ไม่พบออเดอร์นี้";
        final data = snap.data() as Map<String, dynamic>;

        if (data['status'] != 1 || data['rider_id'] != null) {
          throw "งานนี้มีไรเดอร์รับไปแล้ว";
        }

        tx.update(ref, {
          "status": 2,
          "rider_id": rider.uid,
          "rider_name": rider.username,
          "rider_phone": rider.phone,
          "vehicleController": rider.vehicleController ?? "-",
          "rider_image_url": rider.riderImageUrl ?? "",
          "rider_location": {
            "lat": currentPosition?.latitude ?? 0,
            "lng": currentPosition?.longitude ?? 0,
          },
          "acceptedAt": FieldValue.serverTimestamp(),
        });
      });

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "✅ สำเร็จ",
        "รับงานเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Get.off(() => RTrackPage(orderId: orderId));
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "ผิดพลาด",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAccepting = false;
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
          onPressed: () => Get.back(),
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

          final senderLat = (data["sender_lat"] ?? 0).toDouble();
          final senderLng = (data["sender_lng"] ?? 0).toDouble();
          final receiverLat = (data["receiver_lat"] ?? 0).toDouble();
          final receiverLng = (data["receiver_lng"] ?? 0).toDouble();
          final addressSender = data["sender_address"] ?? "-";

          final senderPos = LatLng(senderLat, senderLng);
          final receiverPos = LatLng(receiverLat, receiverLng);

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
                      // รูปสินค้า
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 220,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 50),
                              ),
                      ),
                      const SizedBox(height: 20),

                      _sectionHeader("📦 ข้อมูลผู้ส่ง"),
                      _infoCard([
                        Text("ชื่อผู้ส่ง: $senderName"),
                        Text("เบอร์โทร: $senderPhone"),
                        const SizedBox(height: 8),
                        const Text(
                          "ที่อยู่จัดส่ง:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(addressSender),
                      ]),

                      const SizedBox(height: 16),
                      _sectionHeader("🏠 ข้อมูลผู้รับ"),
                      _infoCard([
                        Text("ชื่อผู้รับ: $receiverName"),
                        Text("เบอร์โทร: $receiverPhone"),
                        const SizedBox(height: 8),
                        const Text(
                          "ที่อยู่จัดส่ง:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(address),
                      ]),

                      const SizedBox(height: 16),
                      _sectionHeader("🛍️ รายการสินค้า"),
                      _infoCard(
                        products.isEmpty
                            ? [const Text("- ไม่มีข้อมูลสินค้า -")]
                            : products.map<Widget>((p) {
                                return Row(
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
                                );
                              }).toList(),
                      ),

                      const SizedBox(height: 16),
                      _sectionHeader("🗺️ แผนที่จัดส่ง"),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              (senderLat + receiverLat) / 2,
                              (senderLng + receiverLng) / 2,
                            ),
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: senderPos,
                                  child: const Icon(
                                    Icons.store_mall_directory,
                                    color: Colors.orange,
                                    size: 38,
                                  ),
                                ),
                                Marker(
                                  point: receiverPos,
                                  child: const Icon(
                                    Icons.home,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ปุ่มรับงาน
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
                    icon: isAccepting
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: Colors.white,
                          ),
                    onPressed: isAccepting
                        ? null
                        : () {
                            final rider = context.read<RiderProvider>();
                            _acceptJob(widget.orderId, data, rider);
                          },
                    label: isAccepting
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

      // Bottom Navigation
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

  /// ===== Widget ย่อย =====

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );

  Widget _infoCard(List<Widget> children) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}
