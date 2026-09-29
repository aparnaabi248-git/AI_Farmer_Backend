import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool darkMode = false;
  bool location = true;

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