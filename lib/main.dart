import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

 
  @override
  void initState() {
    super.initState();
    _loadSavedData(); // استدعاء البيانات تلقائياً عند فتح التطبيق
  }

  // تحميل البيانات والارتباطات والكميات المحفوظة في ذاكرة الجوال
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var chemical in _chemicals) {
        chemical.tagId = prefs.getString('${chemical.name}_tag');
        chemical.quantity = prefs.getInt('${chemical.name}_qty') ?? 0;
      }
    });
  }

  // حفظ بيانات مادة معينة فور تعديلها
  Future<void> _saveChemicalData(Chemical chemical) async {
    final prefs = await SharedPreferences.getInstance();
    if (chemical.tagId != null) {
      await prefs.setString('${chemical.name}_tag', chemical.tagId!);
    }
    await prefs.setInt('${chemical.name}_qty', chemical.quantity);
  }

  // دالة تشغيل الـ NFC القياسية والمستقرة والمحمية من الـ Crash
Future<void> _startNFC() async {
  try {
final availability =
    await NfcManager.instance.checkAvailability();

if (availability != NfcAvailability.enabled) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("⚠️ ميزة NFC غير مفعلة أو غير مدعومة")),
  );
  return;
}

    setState(() {
      _isScanning = true;
    });

    await NfcManager.instance.stopSession().catchError((_) {});

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          String scannedPayload = tag.toString();

          setState(() {
            _isScanning = false;

            if (scannedPayload.contains("TYJ10") || scannedPayload == "TYJ10") {
              _chemicals[0].tagId = "TYJ10";
              _chemicals[1].tagId = "TYJ10";
              _saveChemicalData(_chemicals[0]);
              _saveChemicalData(_chemicals[1]);
            } else {
              _chemicals[_selectedIndex].tagId = scannedPayload;
              _saveChemicalData(_chemicals[_selectedIndex]);
            }
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ تم معالجة بطاقة NFC بنجاح!"),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print("خطأ داخلي أثناء المعالجة: $e");
        } finally {
          await NfcManager.instance.stopSession().catchError((_) {});
          setState(() {
            _isScanning = false;
          });
        }
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
      _saveChemicalData(_chemicals[index]); // حفظ الكمية الجديدة
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (_chemicals[index].quantity > 0) {
        _chemicals[index].quantity--;
        _saveChemicalData(_chemicals[index]); // حفظ الكمية الجديدة
      }
    });
  }

  // ميزة إضافة مواد جديدة ديناميكياً عبر نافذة منبثقة واحترافية
  void _addNewChemicalDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController formulaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("إضافة مادة جديدة للمختبر"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "اسم المادة الكيميائية"),
                ),
                TextField(
                  controller: formulaController,
                  decoration: const InputDecoration(labelText: "الصيغة البرمجية أو الكيميائية (مثال: H₂O)"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && formulaController.text.isNotEmpty) {
                    setState(() {
                      var newChem = Chemical(
                        name: nameController.text,
                        formula: formulaController.text,
                      );
                      _chemicals.add(newChem);
                      _saveChemicalData(newChem);
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("إضافة المادة"),
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
      appBar: AppBar(
        title: const Text("مختبر NFC الذكي", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // إضافة أزرار مدمجة للـ NFC ولإضافة المواد معاً بشكل منسق
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addBtn",
            onPressed: _addNewChemicalDialog,
            backgroundColor: Colors.teal.shade700,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "nfcBtn",
            onPressed: _startNFC,
            backgroundColor: _isScanning ? Colors.orange : Colors.teal,
            icon: Icon(_isScanning ? Icons.sensors : Icons.nfc, color: Colors.white),
            label: Text(
              _isScanning ? "جاري القراءة..." : "ربط بطاقة NFC",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                  itemBuilder: (context, index) {
                    final item = _chemicals[index];
                    bool isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Colors.teal : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // أزرار التحكم بالكمية
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: () => _increaseQty(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _decreaseQty(index),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              // تفاصيل المادة
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      item.formula,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("الكمية المتوفرة: ${item.quantity}", style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          item.tagId != null ? "المعرّف (Tag): مرتبط بنجاح" : "المعرّف (Tag): غير مرتبط",
                                          style: TextStyle(
                                            color: item.tagId != null ? Colors.green : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          item.tagId != null ? Icons.check_circle : Icons.cancel,
                                          color: item.tagId != null ? Colors.green : Colors.red,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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