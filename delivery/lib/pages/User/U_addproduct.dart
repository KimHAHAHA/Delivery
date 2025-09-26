import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // เก็บ list ของสินค้าและจำนวน
  List<Map<String, TextEditingController>> productControllers = [
    {"name": TextEditingController(), "qty": TextEditingController()},
  ];

  // เพิ่มช่องกรอกสินค้า
  void _addProductField() {
    setState(() {
      productControllers.add({
        "name": TextEditingController(),
        "qty": TextEditingController(),
      });
    });
  }

  // ลบช่องกรอกสินค้า
  void _removeProductField(int index) {
    setState(() {
      productControllers.removeAt(index);
    });
  }

  InputDecoration _inputDecoration(String hint, {String? label}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white, // สีพื้นหลังช่องกรอก
      hintText: hint,
      labelText: label, // ✅ label สำหรับ TextField
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
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
          "เพิ่มข้อมูลสินค้า",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header เหลือแค่สินค้า
            const Text("สินค้า", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // ✅ ช่องกรอกสินค้าและจำนวน
            Expanded(
              child: ListView.builder(
                itemCount: productControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        // ช่องสินค้า
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: productControllers[index]["name"],
                            decoration: _inputDecoration("ชื่อสินค้า"),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // ช่องจำนวน (มี label "จำนวน")
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: productControllers[index]["qty"],
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("0", label: "จำนวน"),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ปุ่มลบ (กากบาท)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            _removeProductField(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ✅ ปุ่มเพิ่มสินค้า (อยู่ตรงกลาง)
            Center(
              child: TextButton(
                onPressed: _addProductField,
                child: const Text(
                  "+ เพิ่มสินค้า",
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ ปุ่มยืนยัน
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
                  // TODO: บันทึกสินค้า
                  for (var product in productControllers) {
                    debugPrint(
                      "สินค้า: ${product["name"]!.text}, "
                      "จำนวน: ${product["qty"]!.text}",
                    );
                  }
                },
                child: const Text(
                  "ยืนยันการเพิ่มสินค้า",
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
