import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  final int userId; // for identifying user
  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.100.17/vawc_php/notification.php?user_id=${widget.userId}",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            reports = List<Map<String, dynamic>>.from(data["data"]);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 248, 248, 248),
              Color.fromARGB(255, 13, 98, 196),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
            ? const Center(child: Text("No message available"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final caseNumber = report["case_number"] ?? "N/A";
                  final status = report["status"] ?? "Pending Review";
                  final worker = report["worker"] ?? "Not assigned";
                  final schedule = report["schedule"] ?? "TBA";
                  final message = report["message"] ?? "No new message";

                  final updated_at = report["updated_at"] ?? "N/A";

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Case No: $caseNumber",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Status: $status"),
                          Text("Worker: $worker"),
                          Text("Schedule: $schedule"),
                          const Divider(),
                          Text(
                            "Admin Message:",
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(message),
                          const SizedBox(height: 8),
                          Text(
                            "Updated: $updated_at",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
