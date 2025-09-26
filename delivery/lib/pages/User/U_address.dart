import 'package:flutter/material.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<Map<String, String>> addresses = [
    {"name": "สมชาย", "detail": "บ้าน ของสมชาย", "default": "true"},
    {"name": "สมชาย", "detail": "ที่ทำงาน ของสมชาย", "default": "false"},
    {"name": "สมชาย", "detail": "บ้านแฟน ของสมชาย", "default": "false"},
  ];

  // ✅ ฟังก์ชันตั้งค่าเริ่มต้น
  void _setDefault(int index) {
    setState(() {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i]["default"] = (i == index) ? "true" : "false";
      }
    });
  }

  // ✅ ฟังก์ชันแสดง popup ยืนยันการลบ
  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ยืนยันการลบที่อยู่",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // ปิด popup
                    },
                    child: const Text("ยกเลิก"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        addresses.removeAt(index);
                      });
                      Navigator.pop(context); // ปิด popup
                    },
                    child: const Text("ยืนยัน"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ ฟังก์ชันแสดง popup เพิ่มที่อยู่
  void _showAddAddressDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController labelController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ชื่อผู้ใช้งาน
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "ชื่อผู้ใช้งาน",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ชื่อที่อยู่
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  hintText: "ชื่อที่อยู่",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ที่อยู่
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hintText: "ที่อยู่",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: () {
                      // TODO: เลือก location จากแผนที่
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ปุ่มยืนยัน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        labelController.text.isNotEmpty &&
                        addressController.text.isNotEmpty) {
                      setState(() {
                        addresses.add({
                          "name": nameController.text,
                          "detail":
                              "${labelController.text} ${addressController.text}",
                          "default": "false",
                        });
                      });
                      Navigator.pop(context); // ปิด popup
                    }
                  },
                  child: const Text(
                    "ยืนยัน",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "ที่อยู่",
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ข้อมูลที่อยู่
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address["name"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address["detail"]!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      // ปุ่มเลือก + ลบ
                      Row(
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
                            onPressed: () {
                              _setDefault(index);
                            },
                            child: Text(
                              address["default"] == "true"
                                  ? "ค่าเริ่มต้น"
                                  : "เลือก",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (address["default"] !=
                              "true") // ไม่แสดงปุ่มลบถ้าเป็นค่าเริ่มต้น
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                _showDeleteConfirmDialog(index);
                              },
                              child: const Text(
                                "ลบ",
                                style: TextStyle(fontSize: 14),
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
                  "เพิ่มที่อยู่",
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
