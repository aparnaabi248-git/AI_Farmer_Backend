import 'package:flutter/material.dart';

class MedicineScreen extends StatelessWidget {
  const MedicineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> remedies = [
      {
        "name": "Mancozeb Fungicide",
        "type": "Chemical Fungicide",
        "disease": "Tomato Early Blight, Leaf Spot",
        "dosage": "2-2.5g per Litre of water",
        "instructions": "Spray thoroughly on foliage when initial symptoms appear. Repeat every 10 days if high humidity persists.",
      },
      {
        "name": "Neem Oil Solution",
        "type": "Organic Pesticide",
        "disease": "Aphids, Whiteflies, Spider Mites",
        "dosage": "5ml Neem Oil + 2ml liquid soap per Litre of water",
        "instructions": "Mix in warm water and spray during late evening. Apply weekly for prevention or twice weekly for infestation.",
      },
      {
        "name": "Copper Oxychloride (COC)",
        "type": "Chemical Fungicide/Bactericide",
        "disease": "Potato Late Blight, Bacterial Canker",
        "dosage": "3g per Litre of water",
        "instructions": "Ensure complete coverage of upper and lower leaf surfaces. Do not mix with acid-reacting fertilizers.",
      },
      {
        "name": "Trichoderma Viride",
        "type": "Bio-Fungicide",
        "disease": "Root Rot, Wilt, Seedling Damping-off",
        "dosage": "10g per kg of seeds or 5kg per acre mixed with compost",
        "instructions": "Best used during soil preparation or seed treatment. Enhances soil health and root growth naturally.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Medicine & Remedies"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: remedies.length,
        itemBuilder: (context, index) {
          final remedy = remedies[index];
          final bool isOrganic = remedy["type"]!.toLowerCase().contains("organic") ||
              remedy["type"]!.toLowerCase().contains("bio");

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          remedy["name"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOrganic ? Colors.green.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          remedy["type"]!,
                          style: TextStyle(
                            color: isOrganic ? Colors.green.shade700 : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Treats: ${remedy["disease"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "Dosage: ${remedy["dosage"]}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 5),
                  const Text(
                    "Application Instructions:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    remedy["instructions"]!,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}