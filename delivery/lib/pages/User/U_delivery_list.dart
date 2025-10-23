import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_addproduct.dart';
import 'package:delivery/pages/User/U_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UDeliveryList extends StatefulWidget {
  final String uid; // ✅ รับ uid ของผู้ส่ง (ผู้ใช้ปัจจุบัน)
  const UDeliveryList({super.key, required this.uid});

  @override
  State<UDeliveryList> createState() => _UDeliveryListState();
}

class _UDeliveryListState extends State<UDeliveryList> {
  final TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? receiverData;
  final MapController mapController = MapController();

  List<Map<String, dynamic>> receiverAddresses = [];
  Map<String, dynamic>? selectedReceiverAddress;

  Map<String, dynamic>? senderData;
  List<Map<String, dynamic>> senderAddresses = [];
  Map<String, dynamic>? selectedSenderAddress;

  List<Map<String, dynamic>> products = [];
  File? productImage;

  @override
  void initState() {
    super.initState();
    _loadSenderAddresses();
  }

  // ✅ โหลดที่อยู่ของผู้ส่ง (ผู้ใช้ปัจจุบัน)
  Future<void> _loadSenderAddresses() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final List<dynamic> addrList = List.from(data['addresses'] ?? []);
      setState(() {
        senderData = {"name": data['username'], "phone": data['phone']};
        senderAddresses = addrList.cast<Map<String, dynamic>>();
        selectedSenderAddress = senderAddresses.isNotEmpty
            ? senderAddresses.firstWhere(
                (e) => e['default'] == true,
                orElse: () => senderAddresses.first,
              )
            : null;
      });
    } catch (e) {
      debugPrint("❌ Error loading sender addresses: $e");
    }
  }

  // ✅ ค้นหาผู้รับจากเบอร์โทร
  Future<void> searchReceiver() async {
    final phone = searchController.text.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกหมายเลขโทรศัพท์ก่อนค้นหา",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          receiverData = null;
          receiverAddresses.clear();
          selectedReceiverAddress = null;
        });
        Get.snackbar(
          "ไม่พบข้อมูล",
          "ไม่พบผู้ใช้ที่มีเบอร์นี้",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final data = snapshot.docs.first.data();
      final List<dynamic> addrList = List.from(data['addresses'] ?? []);

      setState(() {
        receiverData = {"name": data['username'], "phone": data['phone']};
        receiverAddresses = addrList.cast<Map<String, dynamic>>();
        selectedReceiverAddress = receiverAddresses.isNotEmpty
            ? receiverAddresses.firstWhere(
                (e) => e['default'] == true,
                orElse: () => receiverAddresses.first,
              )
            : null;
      });

      if (selectedReceiverAddress != null) {
        _moveMapTo(selectedReceiverAddress!);
      }
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ ย้ายแผนที่
  void _moveMapTo(Map<String, dynamic> addr) {
    final lat = addr['lat'] ?? 13.736717;
    final lng = addr['lng'] ?? 100.523186;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          mapController.move(LatLng(lat, lng), 15.0);
        } catch (e) {
          debugPrint("⚠️ ไม่สามารถเลื่อนแผนที่ได้: $e");
        }
      }
    });
  }

  // ✅ ถ่ายภาพสินค้า
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        productImage = File(picked.path);
      });
      Get.snackbar(
        "สำเร็จ",
        "เพิ่มภาพสินค้าเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  // ✅ บันทึกข้อมูลลง Firestore + อัปโหลดภาพไป Supabase
  // ✅ บันทึกข้อมูลลง Firestore + อัปโหลดภาพไป Supabase
  Future<void> _saveOrder() async {
    // ✅ ตรวจสอบข้อมูลผู้ส่ง
    if (senderData == null || selectedSenderAddress == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกที่อยู่ผู้ส่ง",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ ตรวจสอบข้อมูลผู้รับ
    if (receiverData == null || selectedReceiverAddress == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาค้นหาและเลือกที่อยู่ผู้รับ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ ตรวจสอบสินค้า
    if (products.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเพิ่มสินค้าอย่างน้อย 1 รายการ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ ตรวจสอบว่ามีภาพสินค้าหรือยัง
    if (productImage == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาถ่ายหรือเลือกรูปสินค้าก่อนกดยืนยัน",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ แสดงโหลดดิ้งระหว่างบันทึก
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // ✅ อัปโหลดรูปสินค้าขึ้น Supabase
      String? imageUrl;
      if (productImage != null) {
        final fileName = "order_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await Supabase.instance.client.storage
            .from('order-images')
            .upload(fileName, productImage!);
        imageUrl = Supabase.instance.client.storage
            .from('order-images')
            .getPublicUrl(fileName);
      }

      // ✅ บันทึกข้อมูลคำสั่งลง Firestore
      await FirebaseFirestore.instance.collection("orders").add({
        // ผู้ส่ง
        "sender_name": senderData!["name"],
        "sender_phone": senderData!["phone"],
        "sender_address": selectedSenderAddress!['detail'],
        "sender_lat": selectedSenderAddress!['lat'],
        "sender_lng": selectedSenderAddress!['lng'],

        // ผู้รับ
        "receiver_name": receiverData!["name"],
        "receiver_phone": receiverData!["phone"],
        "receiver_address": selectedReceiverAddress!['detail'],
        "receiver_lat": selectedReceiverAddress!['lat'],
        "receiver_lng": selectedReceiverAddress!['lng'],

        // สินค้าและรูป
        "products": products,
        "image_url": imageUrl ?? "",
        "status": 1,
        "rider_id": null,
        "createdAt": Timestamp.now(),
      });

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "สำเร็จ",
        "บันทึกคำสั่งส่งสินค้าเรียบร้อยแล้ว 🎉",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Future.delayed(
        const Duration(seconds: 1),
        () => Get.offAll(() => const UHomePage()),
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถบันทึกข้อมูลได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = selectedReceiverAddress?['lat'] ?? 13.736717;
    final lng = selectedReceiverAddress?['lng'] ?? 100.523186;
    final position = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        title: const Text(
          "รายการส่งสินค้า",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ ส่วนเลือกที่อยู่ผู้ส่ง
            if (senderData != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ที่อยู่ผู้ส่ง (${senderData!["name"]})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedSenderAddress,
                      items: senderAddresses.map((addr) {
                        return DropdownMenuItem(
                          value: addr,
                          child: Text(addr['detail'] ?? "ไม่มีรายละเอียด"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedSenderAddress = value!);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ ค้นหาผู้รับ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "ค้นหาด้วยหมายเลขโทรศัพท์ผู้รับ",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: searchReceiver,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ ข้อมูลผู้รับ
            if (receiverData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiverData!["name"],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(receiverData!["phone"]),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedReceiverAddress,
                      items: receiverAddresses.map((addr) {
                        return DropdownMenuItem(
                          value: addr,
                          child: Text(addr['detail'] ?? "ไม่มีรายละเอียด"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedReceiverAddress = value!);
                        _moveMapTo(value!);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 150,
                      child: FlutterMap(
                        key: ValueKey(lat),
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: position,
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=08c89dd3f9ae427b904737c50b61cb53',
                            userAgentPackageName: 'net.delivery.user',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: position,
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
                    const SizedBox(height: 16),
                    const Text(
                      "ข้อมูลสินค้า",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (products.isEmpty)
                      const Text(
                        "ยังไม่มีสินค้า",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Column(
                        children: products
                            .map(
                              (p) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p["name"]),
                                  Text("x${p["qty"]}"),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    TextButton(
                      onPressed: () async {
                        final result = await Get.to(
                          () => AddProductPage(initialProducts: products),
                        );
                        if (result != null &&
                            result is List<Map<String, dynamic>>) {
                          setState(() => products = result);
                        }
                      },
                      child: const Text(
                        "+ เพิ่มสินค้า",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: productImage == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text("แตะเพื่อถ่ายภาพสินค้า"),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  productImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // ✅ ตรวจสอบก่อนกดส่ง
                          if (senderData == null ||
                              selectedSenderAddress == null ||
                              receiverData == null ||
                              selectedReceiverAddress == null ||
                              products.isEmpty ||
                              productImage == null) {
                            Get.snackbar(
                              "ข้อมูลไม่ครบ",
                              "กรุณากรอกและแนบข้อมูลให้ครบก่อนกดยืนยัน",
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          _saveOrder();
                        },
                        child: const Text(
                          "ยืนยันการส่ง",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
