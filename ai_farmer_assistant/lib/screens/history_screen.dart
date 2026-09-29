import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'disease_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get("/scans/history");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          history = data;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load scan history.")),
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

  String formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  IconData getIconForDisease(String diseaseName) {
    final name = diseaseName.toLowerCase();
    if (name.contains("tomato")) {
      return Icons.local_florist;
    } else if (name.contains("potato")) {
      return Icons.eco;
    } else if (name.contains("corn") || name.contains("maize")) {
      return Icons.grass;
    } else if (name.contains("healthy")) {
      return Icons.check_circle_outline;
    }
    return Icons.spa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History Logs"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : loadHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 80,
                        color: Colors.green.shade200,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "No Scan History Yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Scanned plants will be saved here automatically.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final String disease = item["disease"] ?? "Unknown Diagnosis";
                    final String date = formatDate(item["created_at"] ?? "");

                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            getIconForDisease(disease),
                            color: Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          disease,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Date: $date\nConfidence: ${item["confidence"] ?? 'N/A'}",
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiseaseResultScreen(
                                diseaseData: item,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}