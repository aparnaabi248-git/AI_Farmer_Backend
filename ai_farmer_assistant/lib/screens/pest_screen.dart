import 'package:flutter/material.dart';

class PestScreen extends StatelessWidget {
  const PestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> pests = [
      {
        "name": "Aphids",
        "crop": "Potato, Tomato, Beans",
        "damage": "Suck sap from stems and leaves, causing leaf curl and transmitting viruses.",
        "control": "Spray neem oil solution, introduce ladybugs, or use insecticidal soaps.",
        "severity": "Medium",
      },
      {
        "name": "Whitefly",
        "crop": "Cotton, Tomato, Eggplant",
        "damage": "Excrete honeydew causing sooty mold; leaves turn yellow and drop.",
        "control": "Use yellow sticky traps, spray imidacloprid, or apply insecticidal oil.",
        "severity": "High",
      },
      {
        "name": "Flea Beetles",
        "crop": "Tomato, Potato, Cabbage",
        "damage": "Chew numerous small holes in leaves, giving them a shot-hole appearance.",
        "control": "Apply diatomaceous earth, plant trap crops, or spray spinosad.",
        "severity": "Low",
      },
      {
        "name": "Red Spider Mites",
        "crop": "Corn, Fruits, Vegetables",
        "damage": "Cause yellow speckling on leaves; heavy infestation leads to webbing and defoliation.",
        "control": "Increase humidity, introduce predatory mites, or apply sulfur sprays.",
        "severity": "High",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pest Detection & Control"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: pests.length,
        itemBuilder: (context, index) {
          final pest = pests[index];
          final Color severityColor = pest["severity"] == "High"
              ? Colors.red
              : (pest["severity"] == "Medium" ? Colors.orange : Colors.blue);

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
                      Text(
                        pest["name"]!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: severityColor.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: severityColor),
                        ),
                        child: Text(
                          "Severity: ${pest["severity"]}",
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Target Crops: ${pest["crop"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Damage:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    pest["damage"]!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 5),
                  const Text(
                    "Control Recommendation:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pest["control"]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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