import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const MyApp());
}

// كلاس المادة الكيميائية متوافق تماماً مع Null Safety الحديثة
class Chemical {
  String name;
  String formula;
  int quantity;
  String? tagId;

  Chemical({
    required this.name,
    required this.formula,
    this.quantity = 0,
    this.tagId,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مختبر NFC الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // قائمة المواد الـ 11 المحدثة بصيغها الكيميائية
  final List<Chemical> _chemicals = [
    Chemical(name: "هيدروكسيد الكالسيوم", formula: "Ca(OH)₂"),
    Chemical(name: "هيدروكسيد الصوديوم", formula: "NaOH"),
    Chemical(name: "هيدروكسيد الباريوم", formula: "Ba(OH)₂"),
    Chemical(name: "هيدروكسيد الألمنيوم", formula: "Al(OH)₃"),
    Chemical(name: "كلوريد النحاس", formula: "CuCl₂"),
    Chemical(name: "كلوريد الصوديوم", formula: "NaCl"),
    Chemical(name: "كلوريد البوتاسيوم", formula: "KCl"),
    Chemical(name: "كلوريد الحديد", formula: "FeCl₃"),
    Chemical(name: "كلوريد الباريوم", formula: "BaCl₂"),
    Chemical(name: "كلوريد الزئبق", formula: "HgCl₂"),
    Chemical(name: "كلوريد الأمونيوم", formula: "NH₄Cl"),
  ];

  int _selectedIndex = 0;
  bool _isScanning = false;

  // دالة تشغيل الـ NFC القياسية والمستقرة للتحديث الجديد
  Future<void> _startNFC() async {
    try {
      bool available = await NfcManager.instance.isAvailable();

      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ ميزة NFC غير مفعلة أو غير مدعومة على هذا الجهاز")),
        );
        return;
      }

      setState(() {
        _isScanning = true;
      });

      // تشغيل الجلسة بدون معاملات إضافية تسبب تعارضاً مع التحديث
NfcManager.instance.startSession(
  pollingOptions: {
    NfcPollingOption.iso14443,
    NfcPollingOption.iso18092,
    NfcPollingOption.iso15693,
  },        onDiscovered: (NfcTag tag) async {
          // جلب معرف البطاقة بشكل آمن
final String tagId = tag.toString();
          setState(() {
            _chemicals[_selectedIndex].tagId = tagId;
            _isScanning = false;
          });

          await NfcManager.instance.stopSession();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ تم ربط البطاقة بنجاح بمادة: ${_chemicals[_selectedIndex].name}"),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حساس الـ NFC غير مستعد حالياً")),
      );
    }
  }

  void _increaseQty(int index) {
    setState(() {
      _chemicals[index].quantity++;
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (_chemicals[index].quantity > 0) {
        _chemicals[index].quantity--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مختبر NFC الذكي", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNFC,
        backgroundColor: _isScanning ? Colors.orange : Colors.teal,
        icon: Icon(_isScanning ? Icons.sensors : Icons.nfc, color: Colors.white),
        label: Text(
          _isScanning ? "جاري القراءة..." : "ربط بطاقة NFC",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // توجيه الواجهة بالكامل للغة العربية
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "المادة المحددة للربط حالياً: ${_chemicals[_selectedIndex].name}. اضغطي على زر NFC ثم مرري البطاقة.",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _chemicals.length,
                  itemBuilder: (context, i) {
                    final c = _chemicals[i];
                    final isSelected = _selectedIndex == i;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.teal : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedIndex = i;
                          });
                        },
                        title: Text(
                          "${c.name} (${c.formula})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("الكمية المتوفرة: ${c.quantity}", style: const TextStyle(color: Colors.blueGrey)),
                              const SizedBox(height: 2),
                              Text(
                                "المعرّف (Tag): ${c.tagId != null ? 'مرتبط بقيمة ذكية' : 'غير مرتبط ❌'}",
                                style: TextStyle(
                                  color: c.tagId != null ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => _decreaseQty(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () => _increaseQty(i),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}