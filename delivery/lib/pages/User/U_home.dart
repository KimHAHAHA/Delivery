import 'package:delivery/pages/User/%E0%B9%8AU_track.dart';
import 'package:delivery/pages/User/U_delivery_list.dart';
import 'package:delivery/pages/User/U_proflie.dart';
import 'package:delivery/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:provider/provider.dart';

class UHomePage extends StatefulWidget {
  const UHomePage({super.key});

  @override
  State<UHomePage> createState() => _UHomePageState();
}

class _UHomePageState extends State<UHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Get.to(() => const UHomePage());
        break;

      case 1:
        Get.to(() => const UTrackPage());
        break;

      case 2:
        Get.to(() => const UProfilePage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<UserProvider>().username ?? "...";
    return Scaffold(
      backgroundColor: const Color(0xFF7DE1A4), // เขียวอ่อน
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/Logo.png", // ใส่ path ของโลโก้
                    fit: BoxFit.cover,
                    width: 140,
                    height: 140,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ข้อความทักทาย
              Text(
                "สวัสดี $username",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                "รับ-ส่งอะไรดีวันนี้?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // ปุ่มส่งพัสดุ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Get.to(() => UDeliveryList());
                },
                child: const Text(
                  "ส่งพัสดุ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: "ติดตามการรับ",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }
}
