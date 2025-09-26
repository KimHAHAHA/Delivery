import 'package:delivery/pages/Rider/R_home.dart';
import 'package:delivery/pages/Rider/R_proflie.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class RTrackPage extends StatelessWidget {
  const RTrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF7DE1A4),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ติดตามการส่ง",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แผนที่
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 250,
                color: Colors.grey[300],
                child: Image.asset(
                  "assets/images/map.png", // ใช้รูปแผนที่ mock แทน
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // รายละเอียดการส่ง
            const Text(
              "ส่งเสื้อผ้า",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text("เสื้อผ้ามือสอง", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            const Text(
              "[3] ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // ช่องเพิ่มรูปสถานะ
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "เพิ่มรูปสถานะ",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.black),
                    onPressed: () {
                      // TODO: เพิ่มรูป
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),

            // ปุ่มส่งสำเร็จ
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
                  Get.to(() => const RHomePage());
                },
                child: const Text(
                  "ส่งสำเร็จ",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
