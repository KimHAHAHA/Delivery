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
  const UDeliveryList({super.key});

  @override
  State<UDeliveryList> createState() => _UDeliveryListState();
}

class _UDeliveryListState extends State<UDeliveryList> {
  final TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? receiverData;
  final MapController mapController = MapController();

  List<Map<String, dynamic>> addressList =
      []; // ✅ เก็บรายการที่อยู่ทั้งหมดของผู้รับ
  Map<String, dynamic>? selectedAddress; // ✅ ที่อยู่ที่เลือกอยู่ตอนนี้

  List<Map<String, dynamic>> products = [];
  File? productImage;

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
          addressList.clear();
          selectedAddress = null;
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
        addressList = addrList.cast<Map<String, dynamic>>();
        selectedAddress = addressList.isNotEmpty
            ? addressList.firstWhere(
                (e) => e['default'] == true,
                orElse: () => addressList.first,
              )
            : null;
      });

      // ✅ ขยับแผนที่ไปยังที่อยู่ที่เลือก
      if (selectedAddress != null) {
        _moveMapTo(selectedAddress!);
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
  Future<void> _saveOrder() async {
    if (receiverData == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาค้นหาผู้รับก่อน",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedAddress == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกที่อยู่ผู้รับ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (products.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเพิ่มสินค้าอย่างน้อย 1 รายการ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      String? imageUrl;

      if (productImage != null) {
        final fileName = "order_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await Supabase.instance.client.storage
            .from('order-images')
            .upload(
              fileName,
              productImage!,
              fileOptions: const FileOptions(cacheControl: '3600'),
            );
        imageUrl = Supabase.instance.client.storage
            .from('order-images')
            .getPublicUrl(fileName);
      }

      await FirebaseFirestore.instance.collection("orders").add({
        "receiver_name": receiverData!["name"],
        "receiver_phone": receiverData!["phone"],
        "receiver_address": selectedAddress!['detail'],
        "receiver_lat": selectedAddress!['lat'],
        "receiver_lng": selectedAddress!['lng'],
        "products": products,
        "image_url": imageUrl ?? "",
        "status": 1, // ✅ สถานะเริ่มต้น
        "rider_id": null, // ✅ สำคัญมาก ต้องมี!
        "rider_name": null,
        "rider_phone": null,
        "rider_image_url": null,
        "rider_location": null,
        "createdAt": Timestamp.now(),
      });

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "สำเร็จ",
        "บันทึกคำสั่งส่งสินค้าเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Future.delayed(const Duration(seconds: 1), () {
        Get.offAll(() => const UHomePage());
      });

      setState(() {
        products.clear();
        productImage = null;
      });
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
    final lat = selectedAddress?['lat'] ?? 13.736717;
    final lng = selectedAddress?['lng'] ?? 100.523186;
    final position = LatLng(lat, lng);

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
          "รายการส่งสินค้า",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Search Bar
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

              if (receiverData != null) ...[
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
                      const SizedBox(height: 8),

                      // ✅ Dropdown สำหรับเลือกที่อยู่
                      if (addressList.isNotEmpty) ...[
                        const Text(
                          "เลือกที่อยู่ผู้รับ:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedAddress,
                          items: addressList.map((addr) {
                            return DropdownMenuItem(
                              value: addr,
                              child: Text(addr['detail'] ?? "ไม่มีรายละเอียด"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAddress = value!;
                            });
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
                      ],
                      const SizedBox(height: 10),

                      // ✅ แผนที่
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
                              userAgentPackageName: 'net.gonggang.osm_demo',
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
                      const SizedBox(height: 8),

                      if (products.isEmpty)
                        const Text(
                          "ยังไม่มีสินค้า",
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Column(
                          children: products.map((p) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p["name"]),
                                Text(p["qty"].toString()),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () async {
                          final result = await Get.to(
                            () => AddProductPage(initialProducts: products),
                          );
                          if (result != null &&
                              result is List<Map<String, dynamic>>) {
                            setState(() {
                              products = result;
                            });
                          }
                        },
                        child: const Text(
                          "+ เพิ่มสินค้า",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 8),

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
                                      Text("แตะเพื่อถ่ายภาพประกอบสินค้า"),
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
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (receiverData != null)
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
                    onPressed: _saveOrder,
                    child: const Text(
                      "ยืนยันการส่ง",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
