import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;

  // Fertilizer Form
  final TextEditingController cropFertController = TextEditingController(text: "Wheat");
  final TextEditingController acresFertController = TextEditingController(text: "2.0");
  Map<String, dynamic>? fertResult;
  bool isFertLoading = false;

  // Irrigation Form
  final TextEditingController cropIrrigController = TextEditingController(text: "Tomato");
  final TextEditingController acresIrrigController = TextEditingController(text: "2.0");
  final TextEditingController tempIrrigController = TextEditingController(text: "32.0");
  String selectedSoil = "Loamy";
  Map<String, dynamic>? irrigResult;
  bool isIrrigLoading = false;

  final List<String> soilTypes = ["Loamy", "Clay", "Sandy", "Black Soil", "Red Soil"];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  Future<void> calculateFertilizer() async {
    final crop = cropFertController.text.trim();
    final acres = double.tryParse(acresFertController.text.trim()) ?? 1.0;

    setState(() {
      isFertLoading = true;
    });

    try {
      final response = await ApiService.post("/calculator/fertilizer", {
        "crop": crop,
        "acres": acres,
      });

      if (response.statusCode == 200) {
        setState(() {
          fertResult = jsonDecode(response.body);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isFertLoading = false;
      });
    }
  }

  Future<void> calculateIrrigation() async {
    final crop = cropIrrigController.text.trim();
    final acres = double.tryParse(acresIrrigController.text.trim()) ?? 1.0;
    final temp = double.tryParse(tempIrrigController.text.trim()) ?? 30.0;

    setState(() {
      isIrrigLoading = true;
    });

    try {
      final response = await ApiService.post("/calculator/irrigation", {
        "crop": crop,
        "acres": acres,
        "soil_type": selectedSoil,
        "current_temp": temp,
      });

      if (response.statusCode == 200) {
        setState(() {
          irrigResult = jsonDecode(response.body);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isIrrigLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Agri Dosage & Water Calculator"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.science), text: "Fertilizer NPK"),
            Tab(icon: Icon(Icons.water_drop), text: "Irrigation Schedule"),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: tabController,
            children: [
              // Fertilizer Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("NPK Fertilizer Requirement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            TextField(
                              controller: cropFertController,
                              decoration: InputDecoration(
                                labelText: "Crop Name (Wheat, Rice, Cotton, Tomato...)",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.eco),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: acresFertController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Farm Land Size (Acres)",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.landscape),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calculate, color: Colors.white),
                                label: isFertLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text("Calculate Fertilizer Bags", style: TextStyle(color: Colors.white, fontSize: 16)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                                onPressed: isFertLoading ? null : calculateFertilizer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (fertResult != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Results for ${fertResult!['acres']} Acres of ${fertResult!['crop']}",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  buildBagCard("Urea (46% N)", "${fertResult!['urea_bags_50kg']} Bags", Colors.blue),
                                  buildBagCard("DAP (18-46-0)", "${fertResult!['dap_bags_50kg']} Bags", Colors.amber.shade900),
                                  buildBagCard("MOP (60% K)", "${fertResult!['mop_bags_50kg']} Bags", Colors.purple),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Total Nutrients: ${fertResult!['nitrogen_kg']} kg N, ${fertResult!['phosphorus_kg']} kg P, ${fertResult!['potassium_kg']} kg K",
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: Text("💡 Application Schedule:\n${fertResult!['recommendation']}", style: const TextStyle(height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              // Irrigation Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Irrigation Water & Duration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            TextField(
                              controller: cropIrrigController,
                              decoration: InputDecoration(
                                labelText: "Crop Name",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.eco),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: acresIrrigController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Farm Land Size (Acres)",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.landscape),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: selectedSoil,
                              decoration: InputDecoration(
                                labelText: "Soil Type",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.grass),
                              ),
                              items: soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => selectedSoil = val);
                              },
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.water_drop, color: Colors.white),
                                label: isIrrigLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text("Calculate Water Needed", style: TextStyle(color: Colors.white, fontSize: 16)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                                onPressed: isIrrigLoading ? null : calculateIrrigation,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (irrigResult != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Irrigation Plan for ${irrigResult!['acres']} Acres",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  buildWaterStat("Water Needed", "${irrigResult!['water_req_liters_per_day']} Liters/day", Icons.water),
                                  buildWaterStat("Pump Duration", "${irrigResult!['irrigation_duration_hours']} Hours", Icons.timer),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text("Method: ${irrigResult!['irrigation_method']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: Text("💡 Schedule Advice:\n${irrigResult!['schedule_advice']}", style: const TextStyle(height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBagCard(String name, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Column(
        children: [
          Text(name, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget buildWaterStat(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 4),
            Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        )
      ],
    );
  }
}
