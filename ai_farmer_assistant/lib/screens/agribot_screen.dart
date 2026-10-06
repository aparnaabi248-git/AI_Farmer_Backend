import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

class AgriBotScreen extends StatefulWidget {
  const AgriBotScreen({super.key});

  @override
  State<AgriBotScreen> createState() => _AgriBotScreenState();
}

class _AgriBotScreenState extends State<AgriBotScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  bool isSending = false;

  final List<String> quickPrompts = [
    "Today's Mandi Price",
    "Tomato Blight Remedy",
    "NPK Dosage Guide",
    "PM-Kisan Update",
    "Best Spraying Time",
  ];

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
      final response = await ApiService.get("/bot/history");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          messages.clear();
          for (var item in data) {
            messages.add({
              "sender": "user",
              "text": item["user_message"],
              "time": item["created_at"],
            });
            messages.add({
              "sender": "bot",
              "text": item["bot_response"],
              "time": item["created_at"],
            });
          }
        });
        scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading chat history: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> sendMessage([String? customText]) async {
    final text = customText ?? messageController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      messageController.clear();
    }

    setState(() {
      messages.add({
        "sender": "user",
        "text": text,
        "time": DateTime.now().toIso8601String(),
      });
      isSending = true;
    });
    scrollToBottom();

    try {
      final response = await ApiService.post("/bot/chat", {
        "message": text,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({
            "sender": "bot",
            "text": data["bot_response"],
            "time": data["created_at"],
          });
        });
        scrollToBottom();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get response from AgriBot.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriBot - AI Assistant"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : loadHistory,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.smart_toy,
                                    size: 80,
                                    color: Colors.green.shade400,
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Ask AgriBot Anything!",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Your 24/7 AI Farming Assistant for Mandi prices, disease cures, weather alerts & subsidies.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 25),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: quickPrompts.map((prompt) {
                                      return ActionChip(
                                        avatar: const Icon(Icons.bolt, size: 16, color: Colors.green),
                                        label: Text(prompt),
                                        onPressed: () => sendMessage(prompt),
                                      );
                                    }).toList(),
                                  )
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(15),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isUser = msg["sender"] == "user";

                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser ? Colors.green.shade700 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                                      bottomRight: Radius.circular(isUser ? 0 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    msg["text"]!,
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Quick Prompts Bar if chat active
              if (messages.isNotEmpty)
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickPrompts.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: Text(quickPrompts[idx], style: const TextStyle(fontSize: 12)),
                          onPressed: () => sendMessage(quickPrompts[idx]),
                        ),
                      );
                    },
                  ),
                ),

              if (isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: "Ask about Mandi rates, NPK, disease...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => sendMessage(),
                      child: CircleAvatar(
                        backgroundColor: Colors.green.shade700,
                        radius: 23,
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
