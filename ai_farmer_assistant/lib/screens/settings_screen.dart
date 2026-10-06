import 'package:flutter/material.dart';

import '../api/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool darkMode = false;
  bool location = true;

  late final TextEditingController _urlController =
      TextEditingController(text: ApiService.baseUrl);

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final messenger = ScaffoldMessenger.of(context);
    await ApiService.setBaseUrl(_urlController.text);
    if (!mounted) return;
    setState(() => _urlController.text = ApiService.baseUrl);
    messenger.showSnackBar(
      SnackBar(content: Text("Server set to ${ApiService.baseUrl}")),
    );
  }

  Future<void> _resetUrl() async {
    final messenger = ScaffoldMessenger.of(context);
    await ApiService.setBaseUrl("");
    if (!mounted) return;
    setState(() => _urlController.text = ApiService.baseUrl);
    messenger.showSnackBar(
      const SnackBar(content: Text("Reset to default server")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [

          const Text(
            "General Settings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.notifications,
                color: Colors.green,
              ),
              title: const Text("Notifications"),
              subtitle: const Text("Receive weather and disease alerts"),
              value: notifications,
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
            ),
          ),

          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.location_on,
                color: Colors.red,
              ),
              title: const Text("Location"),
              subtitle: const Text("Allow location for weather updates"),
              value: location,
              onChanged: (value) {
                setState(() {
                  location = value;
                });
              },
            ),
          ),

          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.dark_mode,
                color: Colors.indigo,
              ),
              title: const Text("Dark Mode"),
              subtitle: const Text("Enable dark theme"),
              value: darkMode,
              onChanged: (value) {
                setState(() {
                  darkMode = value;
                });
              },
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Backend Server",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Change this if requests fail. Leave as-is to use the "
                    "deployed server.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: "Server URL",
                      hintText: "http://192.168.1.5:8000",
                      prefixIcon: const Icon(Icons.dns, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveUrl,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetUrl,
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text("Reset"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "About",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.info,
                color: Colors.blue,
              ),
              title: Text("AI Farmer Assistant"),
              subtitle: Text("Version 1.0.0"),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.privacy_tip,
                color: Colors.orange,
              ),
              title: const Text("Privacy Policy"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Privacy Policy Coming Soon"),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.help,
                color: Colors.purple,
              ),
              title: const Text("Help & Support"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Help Center Coming Soon"),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}