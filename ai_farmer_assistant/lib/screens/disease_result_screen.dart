import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_service.dart';

class DiseaseResultScreen extends StatelessWidget {
  final XFile? image;
  final Map<String, dynamic> diseaseData;

  const DiseaseResultScreen({
    super.key,
    this.image,
    required this.diseaseData,
  });

  @override
  Widget build(BuildContext context) {
    final String disease =
        diseaseData["disease"] ?? "Healthy Crop";

    final String confidence =
        diseaseData["confidence"] ?? "100%";

    final String pest =
        diseaseData["pest"] ?? "None";

    final String medicine =
        diseaseData["medicine"] ?? "None";

    final String prevention =
        diseaseData["prevention"] ??
            "Continue regular maintenance.";

    final String? imageUrl =
    diseaseData["image_url"];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Disease Detection Result",
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // =========================
            // IMAGE
            // =========================
            ClipRRect(
              borderRadius: BorderRadius.circular(15),

              child: image != null
                  ? FutureBuilder<Uint8List>(
                future: image!.readAsBytes(),

                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.green.shade50,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.green.shade50,
                      child: const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.green,
                      ),
                    );
                  }

                  return Image.memory(
                    snapshot.data!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              )

                  : imageUrl != null
                  ? Image.network(
                "${ApiService.baseUrl}$imageUrl",
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,

                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.green.shade50,
                    child: const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.green,
                    ),
                  );
                },
              )

                  : Container(
                height: 250,
                width: double.infinity,
                color: Colors.green.shade50,
                child: const Icon(
                  Icons.image,
                  size: 80,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // RESULT CARD
            // =========================
            Card(
              elevation: 5,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  children: [

                    const Icon(
                      Icons.local_florist,
                      size: 60,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Plant Disease Diagnosis",

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Disease
                    buildRow(
                      Icons.coronavirus,
                      "Disease",
                      disease,
                      Colors.red,
                    ),

                    // Confidence
                    buildRow(
                      Icons.analytics,
                      "Confidence",
                      confidence,
                      Colors.blue,
                    ),

                    // Pest
                    buildRow(
                      Icons.bug_report,
                      "Pest",
                      pest,
                      Colors.orange,
                    ),

                    // Medicine
                    buildRow(
                      Icons.medical_services,
                      "Medicine",
                      medicine,
                      Colors.purple,
                    ),

                    const SizedBox(height: 20),

                    // =========================
                    // PREVENTION
                    // =========================
                    const Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        "Prevention Tips",

                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        prevention,

                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =========================
                    // BACK TO HOME
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.home,
                        ),

                        label: const Text(
                          "Back to Home",
                        ),

                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.green,
                          foregroundColor:
                          Colors.white,
                        ),

                        onPressed: () {
                          Navigator.popUntil(
                            context,
                                (route) =>
                            route.isFirst,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // RESULT ROW
  // =========================
  Widget buildRow(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: color,
          ),

          const SizedBox(width: 15),

          Expanded(
            flex: 2,

            child: Text(
              title,

              style: const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),

          Expanded(
            flex: 3,

            child: Text(
              value,

              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}