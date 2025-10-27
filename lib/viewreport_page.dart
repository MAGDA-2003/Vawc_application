import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ViewReportsPage extends StatefulWidget {
  final int userId;

  const ViewReportsPage({super.key, required this.userId});

  @override
  State<ViewReportsPage> createState() => _ViewReportsPageState();
}

class _ViewReportsPageState extends State<ViewReportsPage> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  bool _isImageHidden = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.17/vawc_php/view_report.php"),
        body: {'user_id': widget.userId.toString()},
      );

      print("Raw response: ${response.body}"); // Debug

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          reports = List<Map<String, dynamic>>.from(data["reports"]);
        });
      } else {
        setState(() {
          reports = [];
        });
        print("No reports found: ${data['message']}");
      }

      // Print report IDs safely
      for (var report in reports) {
        print("Report ID: ${report['report_id'].toString()}");
      }
    } catch (e) {
      print("Fetch failed: $e");
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Pending Review":
        return Colors.orange;
      case "Under Evaluation":
        return Colors.blue;
      case "Scheduled for Action":
        return Colors.purple;
      case "Ongoing Case":
        return Colors.green;
      case "Case Closed":
        return Colors.grey;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String getStatusMessage(Map<String, dynamic> report) {
    String status = report["status"] ?? "Pending Review";

    switch (status) {
      case "Pending Review":
        return "Your report is pending review. Please wait for the VAWC staff to evaluate your case.";
      case "Under Evaluation":
        return "Your report is under evaluation by the VAWC team. Updates will follow soon.";
      case "Scheduled for Action":
        return "A schedule has been set.\nSchedule: ${report["schedule"] ?? "TBA"}\nWorker: ${report["worker"] ?? "Not assigned"}";
      case "Ongoing Case":
        return "Case Number: ${report["caseNumber"] ?? "Pending"}\nWorker: ${report["worker"] ?? "Pending"}\nSchedule: ${report["schedule"] ?? "TBA"}";
      case "Case Closed":
        return "Your case has been resolved and marked as closed. Thank you for your cooperation.";
      case "Rejected":
        return "Your report was rejected. Please verify your information and resubmit.";
      default:
        return "No updates available at the moment.";
    }
  }

  void deleteReport(int index) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report"),
        content: const Text("Are you sure you want to delete this report?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        reports.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 147, 167, 213),
      appBar: AppBar(
        title: const Text("View Reports"),
        backgroundColor: const Color.fromARGB(255, 226, 123, 38),
      ),
      body: reports.isEmpty
          ? const Center(child: Text("No reports yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: icon + victim name
                        Row(
                          children: [
                            const Icon(Icons.report, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              report["victim"] ?? "Report",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Image
                        if (report["image"] != null &&
                            report["image"].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    'http://192.168.100.17/vawc_php/${report["image"]}',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Blur overlay when hidden
                                if (_isImageHidden)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ),
                                  ),

                                // Toggle button in the center
                                Positioned(
                                  child: IconButton(
                                    iconSize: 36,
                                    color: Colors.white,
                                    onPressed: () {
                                      setState(() {
                                        _isImageHidden = !_isImageHidden;
                                      });
                                    },
                                    icon: Icon(
                                      _isImageHidden
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    tooltip: _isImageHidden
                                        ? "Show image"
                                        : "Hide image",
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),

                        Text(
                          "Report ID: ${report['report_id'] ?? 'N/A'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text("Type: ${report["type"] ?? "N/A"}"),
                        Text("Location: ${report["location"] ?? "N/A"}"),
                        Text(
                          "Date of Incident: ${report["date"] != null ? DateFormat('MMMM d, y').format(report["date"] is DateTime ? report["date"] : DateTime.tryParse(report["date"]) ?? DateTime.now()) : "N/A"}",
                        ),

                        Text("Time of Incident: ${report["time"] ?? "N/A"}"),
                        Text("Details: ${report["details"] ?? "N/A"}"),

                        const SizedBox(height: 10),
                        const Divider(height: 20, thickness: 1),

                        // Victim Info
                        const Text(
                          "Victim Information",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text("Name: ${report["victim"] ?? "N/A"}"),
                        Text("Contact: ${report["victimContact"] ?? "N/A"}"),
                        Text("Email: ${report["victimEmail"] ?? "N/A"}"),
                        Text("Address: ${report["victimAddress"] ?? "N/A"}"),

                        const SizedBox(height: 10),
                        const Text(
                          "Perpetrator Information",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text("Name: ${report["perpetratorName"] ?? "N/A"}"),
                        Text(
                          "Contact: ${report["perpetratorContact"] ?? "N/A"}",
                        ),
                        Text("Email: ${report["perpetratorEmail"] ?? "N/A"}"),
                        Text(
                          "Address: ${report["perpetratorAddress"] ?? "N/A"}",
                        ),
                        Text(
                          "Relationship: ${report["relationship"] ?? "N/A"}",
                        ),

                        const SizedBox(height: 8),
                        Text(
                          "Reported on: ${DateFormat('MMMM d, y – h:mm a').format(report["created_at"] is DateTime ? report["created_at"] : DateTime.tryParse(report["created_at"] ?? '') ?? DateTime.now())}",
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),

                        const Divider(height: 20, thickness: 1),

                        Text(
                          "Status: ${(report["status"] == null || report["status"].toString().isEmpty) ? "Pending Review" : report["status"]}",
                          style: TextStyle(
                            color: getStatusColor(
                              (report["status"] == null ||
                                      report["status"].toString().isEmpty)
                                  ? "Pending Review"
                                  : report["status"],
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          getStatusMessage(report),
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
