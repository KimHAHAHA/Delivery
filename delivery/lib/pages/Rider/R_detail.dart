import 'package:delivery/pages/Rider/R_home.dart';
import 'package:delivery/pages/Rider/R_proflie.dart' hide RHomePage;
import 'package:delivery/pages/Rider/R_track.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class RDetailPage extends StatefulWidget {
  const RDetailPage({super.key});

  @override
  State<RDetailPage> createState() => _RDetailPageState();
}

class _RDetailPageState extends State<RDetailPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Get.to(() => const RHomePage());
    } else {
      Get.to(() => const RProfilePage());
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

      // ✅ ใช้ Column + Expanded เพื่อดันปุ่มลงล่าง
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // ✅ เว้นระยะรูปจาก AppBar
                  // รูปสินค้า
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/Logo.png", // แก้ path เป็นรูปจริง
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ข้อมูลชื่อผู้ส่ง
                  const Text(
                    "สมชาย",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // ตำแหน่ง
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.pink, size: 18),
                      SizedBox(width: 6),
                      Text("18 เมตร สถานที่รับสินค้า"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.pink, size: 18),
                      SizedBox(width: 6),
                      Text("100 เมตร สถานที่ส่งสินค้า"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // รายการสินค้า
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "สินค้า",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "จำนวน",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text("รองเท้าผ้าใบ"), Text("1")],
                  ),
                  const SizedBox(height: 10),

                  // เบอร์โทร
                  const Text("เบอร์ผู้ส่ง: 081"),
                  const Text("เบอร์ผู้รับ: 088"),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ✅ ปุ่มรับงานอยู่ล่างสุด
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
                onPressed: () {
                  Get.to(() => RTrackPage());
                },
                child: const Text(
                  "รับงาน",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
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
