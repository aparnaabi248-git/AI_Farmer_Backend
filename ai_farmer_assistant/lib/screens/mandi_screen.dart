import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  List<dynamic> mandiItems = [];
  bool isLoading = false;
  String selectedCategory = "All";
  final TextEditingController searchController = TextEditingController();

  final List<String> categories = ["All", "Cereals", "Vegetables", "Cash Crops", "Oilseeds"];

  @override
  void initState() {
    super.initState();
    fetchMandiPrices();
  }

  Future<void> fetchMandiPrices() async {
    setState(() {
      isLoading = true;
    });

    try {
      String query = "/mandi/prices?category=${Uri.encodeComponent(selectedCategory)}";
      final search = searchController.text.trim();
      if (search.isNotEmpty) {
        query += "&search=${Uri.encodeComponent(search)}";
      }

      final response = await ApiService.get(query);
      if (response.statusCode == 200) {
        setState(() {
          mandiItems = jsonDecode(response.body);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch Mandi market prices.")),
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

  Color getTrendColor(String trend) {
    if (trend == "UP") return Colors.green;
    if (trend == "DOWN") return Colors.red;
    return Colors.orange;
  }

  IconData getTrendIcon(String trend) {
    if (trend == "UP") return Icons.trending_up;
    if (trend == "DOWN") return Icons.trending_down;
    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Real-Time Mandi Prices"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchMandiPrices,
          )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search crop (Wheat, Rice, Cotton...)",
                        prefixIcon: const Icon(Icons.search, color: Colors.green),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  fetchMandiPrices();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => fetchMandiPrices(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: fetchMandiPrices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text("Search", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Category Filter Bar
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.green.shade600,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedCategory = cat;
                            });
                            fetchMandiPrices();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              // Main List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : mandiItems.isEmpty
                        ? const Center(
                            child: Text(
                              "No Mandi records found for this query.",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: mandiItems.length,
                            itemBuilder: (context, index) {
                              final item = mandiItems[index];
                              final String commodity = item["commodity"] ?? "";
                              final String mandi = item["mandi_name"] ?? "";
                              final String state = item["state"] ?? "";
                              final double modal = (item["modal_price"] as num).toDouble();
                              final double minP = (item["min_price"] as num).toDouble();
                              final double maxP = (item["max_price"] as num).toDouble();
                              final double change = (item["price_change"] as num).toDouble();
                              final String trend = item["trend"] ?? "STABLE";
                              final String tip = item["selling_tip"] ?? "";

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
                                          Expanded(
                                            child: Text(
                                              commodity,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: getTrendColor(trend).withAlpha(30),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: getTrendColor(trend)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  getTrendIcon(trend),
                                                  size: 18,
                                                  color: getTrendColor(trend),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%",
                                                  style: TextStyle(
                                                    color: getTrendColor(trend),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$mandi, $state",
                                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Modal Rate", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                              Text(
                                                "₹${modal.toStringAsFixed(0)} / Qtl",
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text("Min - Max Range", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                              Text(
                                                "₹${minP.toStringAsFixed(0)} - ₹${maxP.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (tip.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.lightGreen.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "AI Selling Tip: $tip",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.green.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
