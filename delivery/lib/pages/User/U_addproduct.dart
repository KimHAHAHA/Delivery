import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialProducts; // ✅ รับสินค้าที่มีอยู่แล้ว

  const AddProductPage({super.key, this.initialProducts});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  List<Map<String, TextEditingController>> productControllers = [];

  @override
  void initState() {
    super.initState();

    // ✅ ถ้ามีข้อมูลสินค้าเก่า → preload เข้า controller
    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      for (var item in widget.initialProducts!) {
        productControllers.add({
          "name": TextEditingController(text: item["name"] ?? ""),
          "qty": TextEditingController(text: item["qty"]?.toString() ?? ""),
        });
      }
    } else {
      // ถ้าไม่มี → เพิ่มแถวว่าง
      productControllers.add({
        "name": TextEditingController(),
        "qty": TextEditingController(),
      });
    }
  }

  void _addProductField() {
    setState(() {
      productControllers.add({
        "name": TextEditingController(),
        "qty": TextEditingController(),
      });
    });
  }

  void _removeProductField(int index) {
    setState(() {
      productControllers.removeAt(index);
    });
  }

  InputDecoration _inputDecoration(String hint, {String? label}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      labelText: label,
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
        title: const Text(
          "เพิ่ม / แก้ไขสินค้า",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: productControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: productControllers[index]["name"],
                            decoration: _inputDecoration("ชื่อสินค้า"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: productControllers[index]["qty"],
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("0", label: "จำนวน"),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeProductField(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: _addProductField,
              child: const Text(
                "+ เพิ่มสินค้า",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final result = productControllers
                      .map(
                        (p) => {
                          "name": p["name"]!.text.trim(),
                          "qty": p["qty"]!.text.trim(),
                        },
                      )
                      .where(
                        (p) => p["name"]!.isNotEmpty && p["qty"]!.isNotEmpty,
                      )
                      .toList();
                  Navigator.pop(context, result);
                },
                child: const Text("ยืนยัน"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
