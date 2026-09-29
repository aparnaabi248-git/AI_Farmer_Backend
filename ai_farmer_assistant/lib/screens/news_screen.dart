import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> newsItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get("/news/latest");
      if (response.statusCode == 200) {
        setState(() {
          newsItems = jsonDecode(response.body);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch agri news.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyError(e))),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getTagColor(String tag) {
    if (tag.contains("PM-KISAN")) return Colors.blue;
    if (tag.contains("MSP")) return Colors.purple;
    if (tag.contains("SOLAR")) return Colors.orange;
    if (tag.contains("CROP")) return Colors.red;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Agri News & Subsidies"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchNews,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : newsItems.isEmpty
                  ? const Center(child: Text("No updates available."))
                  : ListView.builder(
                      itemCount: newsItems.length,
                      itemBuilder: (context, index) {
                        final item = newsItems[index];
                        final String title = item["title"] ?? "";
                        final String category = item["category"] ?? "";
                        final String summary = item["summary"] ?? "";
                        final String date = item["date"] ?? "";
                        final String tag = item["tag"] ?? "NEWS";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: getTagColor(tag).withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: getTagColor(tag),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      date,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  summary,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.category, size: 16, color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
