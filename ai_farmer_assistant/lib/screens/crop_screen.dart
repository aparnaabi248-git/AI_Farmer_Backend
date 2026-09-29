import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();
  final TextEditingController rainfallController = TextEditingController();
  final TextEditingController soilController = TextEditingController();

  String crop = "";
  String season = "";
  String fertilizer = "";
  bool isLoading = false;

  Future<void> recommendCrop() async {
    final String tempText = temperatureController.text.trim();
    final String humidityText = humidityController.text.trim();
    final String rainfallText = rainfallController.text.trim();
    final String soil = soilController.text.trim();

    if (tempText.isEmpty || humidityText.isEmpty || rainfallText.isEmpty || soil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.post("/crops/recommend", {
        "temperature": double.tryParse(tempText) ?? 0.0,
        "humidity": double.tryParse(humidityText) ?? 0.0,
        "rainfall": double.tryParse(rainfallText) ?? 0.0,
        "soil_type": soil,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          crop = data["crop"];
          season = data["season"];
          fertilizer = data["fertilizer"];
        });
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["detail"] ?? "Failed to get recommendations.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget resultTile(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Recommendation"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildTextField(
              temperatureController,
              "Temperature (°C)",
              Icons.thermostat,
            ),
            buildTextField(
              humidityController,
              "Humidity (%)",
              Icons.water_drop,
            ),
            buildTextField(
              rainfallController,
              "Rainfall (mm)",
              Icons.cloud,
            ),
            buildTextField(
              soilController,
              "Soil Type (e.g. Clay, Black, Red, Loamy)",
              Icons.grass,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : recommendCrop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Recommend Crop",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 25),
            if (crop.isNotEmpty) ...[
              resultTile(
                "Recommended Crop",
                crop,
                Icons.eco,
              ),
              resultTile(
                "Best Season",
                season,
                Icons.calendar_month,
              ),
              resultTile(
                "Suggested Fertilizer",
                fertilizer,
                Icons.local_florist,
              ),
            ]
          ],
        ),
      ),
    );
  }
}