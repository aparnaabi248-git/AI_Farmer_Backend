import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final List<String> cities = ["Chennai", "Mumbai", "Delhi", "Bengaluru", "Hyderabad", "Kolkata", "Pune"];
  String selectedCity = "Chennai";
  final TextEditingController searchController = TextEditingController();

  Map<String, dynamic>? weatherData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWeather(selectedCity);
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get("/weather?city=${Uri.encodeComponent(city)}");
      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
          selectedCity = city;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch weather forecast.")),
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

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'heavy rain':
      case 'rain':
      case 'showers':
        return Icons.water_drop;
      case 'partly cloudy':
      case 'cloudy':
        return Icons.cloud;
      case 'dry heat':
        return Icons.wb_twilight;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }

  Color getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Colors.orange;
      case 'heavy rain':
      case 'rain':
        return Colors.blue;
      case 'partly cloudy':
      case 'cloudy':
        return Colors.grey.shade700;
      case 'dry heat':
        return Colors.deepOrange;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String condition = weatherData?["condition"] ?? "Sunny";
    final double temp = (weatherData?["temperature"] as num?)?.toDouble() ?? 30.0;
    final int humidity = weatherData?["humidity"] ?? 65;
    final double wind = (weatherData?["wind_speed"] as num?)?.toDouble() ?? 12.0;
    final String advice = weatherData?["farming_advice"] ?? "Weather is stable.";
    final bool spraySafe = weatherData?["spraying_window_safe"] ?? true;
    final String sprayAdvice = weatherData?["spraying_advice"] ?? "Spraying conditions are normal.";
    final List<dynamic> forecast = weatherData?["forecast"] ?? [];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Real-Time Weather & Agromet"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Location Selector Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: cities.contains(selectedCity) ? selectedCity : null,
                            hint: Text(selectedCity),
                            isExpanded: true,
                            items: cities.map((String city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              );
                            }).toList(),
                            onChanged: (String? val) {
                              if (val != null) fetchWeather(val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search City...",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (searchController.text.trim().isNotEmpty) {
                                fetchWeather(searchController.text.trim());
                                searchController.clear();
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        children: [
                          // Main Weather Card
                          Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    getWeatherIcon(condition),
                                    color: getWeatherColor(condition),
                                    size: 90,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    selectedCity,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "${temp.toStringAsFixed(1)}°C",
                                    style: TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    condition,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Spraying Window Status Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: spraySafe ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: spraySafe ? Colors.green : Colors.red),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  spraySafe ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: spraySafe ? Colors.green.shade800 : Colors.red.shade800,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spraySafe ? "Pesticide Spraying Safe Today" : "Spraying Caution Recommended",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: spraySafe ? Colors.green.shade900 : Colors.red.shade900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(sprayAdvice, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Weather Stat Tiles
                          Row(
                            children: [
                              Expanded(child: buildSmallStatTile(Icons.water_drop, "Humidity", "$humidity%", Colors.blue)),
                              const SizedBox(width: 10),
                              Expanded(child: buildSmallStatTile(Icons.air, "Wind Speed", "$wind km/h", Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Forecast Slider / List
                          if (forecast.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "5-Day Forecast",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 125,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: forecast.length,
                                itemBuilder: (context, index) {
                                  final item = forecast[index];
                                  final day = item["day"] ?? "";
                                  final tMax = (item["temp_max"] as num).toDouble();
                                  final tMin = (item["temp_min"] as num).toDouble();
                                  final cond = item["condition"] ?? "Sunny";
                                  final rainProb = item["rain_probability"] ?? 0;

                                  return Container(
                                    width: 110,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(12),
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Icon(getWeatherIcon(cond), color: getWeatherColor(cond), size: 28),
                                        const SizedBox(height: 4),
                                        Text("${tMax.toStringAsFixed(0)}° / ${tMin.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        Text("☔ $rainProb%", style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 25),
                          ],

                          // Farming Advice Card
                          Card(
                            color: Colors.green.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.tips_and_updates,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Farming Advisory",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    advice,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 15, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSmallStatTile(IconData icon, String title, String val, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}