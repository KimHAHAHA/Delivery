import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class AddressPage extends StatefulWidget {
  final String username; // รับชื่อผู้ใช้ที่ล็อกอินมา
  const AddressPage({super.key, required this.username});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  // ✅ ตัวแปรหลัก
  List<Map<String, dynamic>> addresses = [];
  final MapController mapController = MapController();
  LatLng currentPosition = const LatLng(
    13.736717,
    100.523186,
  ); // เริ่มต้นกรุงเทพ

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // ✅ โหลดข้อมูลที่อยู่จาก Firestore
  Future<void> _loadAddresses() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.username)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final List<dynamic>? list = data['addresses'];

        setState(() {
          addresses = (list ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "โหลดข้อมูลไม่สำเร็จ: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ ดึงตำแหน่งปัจจุบันจาก GPS
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services ปิดอยู่';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'สิทธิ์ถูกปฏิเสธถาวร';
    }

    return await Geolocator.getCurrentPosition();
  }

  // ✅ ตั้งค่าที่อยู่เริ่มต้น
  void _setDefault(int index) async {
    setState(() {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i]["default"] = (i == index);
      }
    });

    await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.username)
        .update({"addresses": addresses});

    Get.snackbar(
      "สำเร็จ",
      "ตั้งค่าที่อยู่เริ่มต้นแล้ว",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // ✅ ลบที่อยู่
  void _deleteAddress(int index) async {
    setState(() {
      addresses.removeAt(index);
    });

    await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.username)
        .update({"addresses": addresses});

    Get.snackbar(
      "ลบสำเร็จ",
      "ที่อยู่ถูกลบเรียบร้อยแล้ว",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // ✅ เพิ่มที่อยู่ใหม่
  void _showAddAddressDialog() {
    final TextEditingController detailController = TextEditingController();
    LatLng selectedPosition = currentPosition;
    final TextEditingController gpsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "เพิ่มที่อยู่ใหม่",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // รายละเอียดที่อยู่
                    TextField(
                      controller: detailController,
                      decoration: const InputDecoration(
                        labelText: "รายละเอียดที่อยู่",
                        hintText: "เช่น บ้าน, ที่ทำงาน, ร้าน ฯลฯ",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // พิกัด
                    TextField(
                      controller: gpsController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "พิกัด (Latitude, Longitude)",
                        hintText: "เลือกตำแหน่งจากแผนที่หรือกดปุ่ม GPS",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            try {
                              Position pos = await _determinePosition();
                              setState(() {
                                selectedPosition = LatLng(
                                  pos.latitude,
                                  pos.longitude,
                                );
                                gpsController.text =
                                    "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
                              });
                              Get.snackbar(
                                'ตำแหน่งปัจจุบัน',
                                gpsController.text,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } catch (e) {
                              Get.snackbar(
                                'ผิดพลาด',
                                'ไม่สามารถดึงตำแหน่งได้: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // แผนที่
                    SizedBox(
                      height: 220,
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: selectedPosition,
                          initialZoom: 15.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              selectedPosition = point;
                              gpsController.text =
                                  "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                            userAgentPackageName: 'net.gonggang.osm_demo',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selectedPosition,
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

                    const SizedBox(height: 20),

                    // ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text("บันทึกที่อยู่"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (detailController.text.isEmpty ||
                              gpsController.text.isEmpty) {
                            Get.snackbar(
                              "ข้อมูลไม่ครบ",
                              "กรุณากรอกที่อยู่และเลือกพิกัดก่อนบันทึก",
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final newAddress = {
                            "detail": detailController.text.trim(),
                            "gps": gpsController.text.trim(),
                            "lat": selectedPosition.latitude,
                            "lng": selectedPosition.longitude,
                            "default": addresses.isEmpty,
                            "createdAt": DateTime.now(),
                          };

                          setState(() {
                            // ✅ แสดงที่อยู่ใหม่บนสุด
                            addresses.insert(0, newAddress);
                          });

                          await FirebaseFirestore.instance
                              .collection('user')
                              .doc(widget.username)
                              .update({"addresses": addresses});

                          await _loadAddresses(); // ✅ โหลดใหม่หลังเพิ่ม

                          Navigator.pop(context);
                          Get.snackbar(
                            "สำเร็จ",
                            "เพิ่มที่อยู่ใหม่เรียบร้อยแล้ว",
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
          "ที่อยู่ของฉัน",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: addresses.isEmpty
                ? const Center(
                    child: Text(
                      "ยังไม่มีที่อยู่",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      final isDefault = addr["default"] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDefault
                              ? Colors.lightGreenAccent.withOpacity(0.7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ข้อมูลที่อยู่
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addr["detail"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isDefault)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "(ที่อยู่เริ่มต้น)",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () => _setDefault(index),
                                  child: Text(
                                    isDefault ? "ค่าเริ่มต้น" : "เลือก",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (!isDefault)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () => _deleteAddress(index),
                                    child: const Text(
                                      "ลบ",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ✅ ปุ่มเพิ่มที่อยู่
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showAddAddressDialog,
                child: const Text(
                  "เพิ่มที่อยู่ใหม่",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
