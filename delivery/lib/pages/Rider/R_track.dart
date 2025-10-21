import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/Rider/R_home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RTrackPage extends StatefulWidget {
  final String orderId;

  const RTrackPage({super.key, required this.orderId});

  @override
  State<RTrackPage> createState() => _RTrackPageState();
}

class _RTrackPageState extends State<RTrackPage> {
  File? statusImage;
  bool isLoading = false;

  // ✅ ฟังก์ชันเลือกภาพจากกล้อง
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        statusImage = File(picked.path);
      });
    }
  }

  // ✅ อัปโหลดภาพไป Supabase
  Future<String?> _uploadImage(File file, String folder) async {
    try {
      final fileName = "${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await Supabase.instance.client.storage
          .from('order-status')
          .upload(fileName, file);

      return Supabase.instance.client.storage
          .from('order-status')
          .getPublicUrl(fileName);
    } catch (e) {
      Get.snackbar(
        "อัปโหลดล้มเหลว",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // ✅ อัปเดตสถานะสินค้า
  Future<void> _updateStatus(Map<String, dynamic> data) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId);

      int status = data["status"] ?? 2;
      int newStatus = status + 1; // ขยับสถานะ

      String? imageUrl;
      if (statusImage != null) {
        imageUrl = await _uploadImage(statusImage!, "status$newStatus");
      }

      final updateData = {"status": newStatus, "updatedAt": Timestamp.now()};

      if (imageUrl != null) {
        updateData["image_url_status$newStatus"] = imageUrl;
      }

      await docRef.update(updateData);

      if (newStatus >= 4) {
        // ส่งสำเร็จ กลับหน้า Home
        Get.snackbar(
          "สำเร็จ",
          "อัปเดตสถานะเป็นส่งสำเร็จแล้ว!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAll(() => const RHomePage());
      } else {
        Get.snackbar(
          "สำเร็จ",
          "อัปเดตสถานะเป็น [$newStatus] แล้ว",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }

      setState(() {
        statusImage = null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถอัปเดตสถานะได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
          "ติดตามการส่ง",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("ไม่พบข้อมูลออเดอร์นี้"));
          }

          final receiver = data["receiver_name"] ?? "-";
          final address = data["receiver_address"] ?? "-";
          final products = data["products"] ?? [];
          final status = data["status"] ?? 1;

          String statusText = switch (status) {
            1 => "[1] รอไรเดอร์มารับสินค้า",
            2 => "[2] ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)",
            3 => "[3] ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง",
            4 => "[4] ไรเดอร์นำส่งสินค้าแล้ว",
            _ => "ไม่ทราบสถานะ",
          };

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Mock map
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.map, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "ผู้รับ: $receiver",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(address),
                const SizedBox(height: 10),

                const Text(
                  "รายการสินค้า:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...products.map((p) => Text("- ${p["name"]} (${p["qty"]})")),

                const SizedBox(height: 16),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ ช่องเพิ่มรูปสถานะ
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: statusImage == null
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
                                Text("แตะเพื่อถ่ายภาพประกอบสถานะ"),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              statusImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),

                const Spacer(),

                // ✅ ปุ่มอัปเดตสถานะ
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status >= 4 ? Colors.grey : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: status >= 4 ? null : () => _updateStatus(data),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            status == 2
                                ? "ถึงจุดรับของแล้ว"
                                : status == 3
                                ? "ส่งสำเร็จ"
                                : "อัปเดตสถานะ",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
