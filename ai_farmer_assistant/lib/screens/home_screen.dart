import 'dart:convert';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'camera_screen.dart';
import 'weather_screen.dart';
import 'crop_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'pest_screen.dart';
import 'medicine_screen.dart';
import 'analytics_screen.dart';
import 'agribot_screen.dart';
import 'mandi_screen.dart';
import 'news_screen.dart';
import 'calculator_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  String userEmail = "";
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await ApiService.get("/auth/me");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userName = data["name"] ?? "Farmer";
            userEmail = data["email"] ?? "";
            isLoadingUser = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userName = "Farmer";
            userEmail = "";
            isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = "Farmer";
          userEmail = "";
          isLoadingUser = false;
        });
      }
    }
  }

  Widget buildCard(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "AI Farmer Assistant",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.agriculture,
                  size: 40,
                  color: Colors.green,
                ),
              ),
              accountName: Text(
                isLoadingUser ? "Loading..." : userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                isLoadingUser ? "" : userEmail,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.green),
              title: const Text("Real-Time Mandi Prices"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MandiScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.blue),
              title: const Text("Weather Forecast"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: Colors.purple),
              title: const Text("Dosage & Water Calculator"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper, color: Colors.amber),
              title: const Text("Agri News & Subsidies"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History Logs"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AgriBotScreen()));
        },
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          "Ask AgriBot",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Live Real-Time Banner Ticker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade800, Colors.teal.shade700],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.online_prediction, color: Colors.yellowAccent, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Real-Time Farm Status • Live",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Wheat ₹2,350/Qtl (UP ⬆️) • Ideal Spraying Window • PM-Kisan 19th Installment Active",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Smart Farming Tools",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    buildCard(
                      context,
                      Icons.camera_alt,
                      "Scan Plant",
                      "Instant Leaf Diagnosis",
                      Colors.green,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.storefront,
                      "Mandi Prices",
                      "Live APMC Rates",
                      Colors.teal,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MandiScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.cloud,
                      "Weather",
                      "5-Day & Agromet Alert",
                      Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.calculate,
                      "Dosage & Water",
                      "NPK & Irrigation Calc",
                      Colors.purple,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.newspaper,
                      "News & Subsidies",
                      "PM-Kisan & MSP Rates",
                      Colors.amber.shade900,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.eco,
                      "Crop Advisory",
                      "Soil & Season Match",
                      Colors.orange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.bug_report,
                      "Pest Control",
                      "Insect & Bug Solvers",
                      Colors.red,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PestScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.medical_services,
                      "Remedies",
                      "Fungicide Dosage",
                      Colors.indigo,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.analytics,
                      "Analytics",
                      "Crop Yield Insights",
                      Colors.brown,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                    ),
                    buildCard(
                      context,
                      Icons.history,
                      "Scan History",
                      "Past Diagnoses",
                      Colors.deepOrange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
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
}