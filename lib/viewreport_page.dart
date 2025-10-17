import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'editreport_page.dart';

class ViewReportsPage extends StatefulWidget {
  final List<Map<String, dynamic>> reports;

  const ViewReportsPage({super.key, required this.reports});

  @override
  State<ViewReportsPage> createState() => _ViewReportsPageState();
}

bool _isImageHidden = true;

class _ViewReportsPageState extends State<ViewReportsPage> {
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

  void showNotification(BuildContext context, Map<String, dynamic> report) {
    final caseNumber = report["caseNumber"] ?? "N/A";
    final status =
        (report["status"] == null || report["status"].toString().isEmpty)
        ? "Pending Review"
        : report["status"];

    final worker = report["worker"] ?? "Not assigned";
    final schedule = report["schedule"] ?? "TBA";
    final timestamp = report["timestamp"] is DateTime
        ? report["timestamp"]
        : DateTime.tryParse(report["timestamp"] ?? '') ?? DateTime.now();

    final formattedTimestamp = DateFormat(
      'MMMM d, y – h:mm a',
    ).format(timestamp);

    // Construct the message for SnackBar
    final message =
        '''
      Case Number: $caseNumber
      Status: $status
      VAWC Worker: $worker
      Schedule: $schedule
      Message Time: $formattedTimestamp
      ''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color.fromARGB(255, 213, 122, 32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        widget.reports.removeAt(index);
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
      body: widget.reports.isEmpty
          ? const Center(child: Text("No reports yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.reports.length,
              itemBuilder: (context, index) {
                final report = widget.reports[index];
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
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.report,
                                  color: Colors.redAccent,
                                ),
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
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_active,
                                color: Colors.blue,
                              ),
                              tooltip: "View Case Update",
                              onPressed: () =>
                                  showNotification(context, report),
                            ),
                          ],
                        ),
                        if (report["imagePath"] != null &&
                            report["imagePath"].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(report["imagePath"]),
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

                        const SizedBox(height: 8),

                        Text("Type: ${report["type"] ?? "N/A"}"),
                        Text("Location: ${report["location"] ?? "N/A"}"),
                        Text("Date of Incident: ${report["date"] ?? "N/A"}"),
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

                        Text(
                          "Reported on: ${DateFormat('MMMM d, y – h:mm a').format(report["timestamp"] is DateTime ? report["timestamp"] : DateTime.tryParse(report["timestamp"] ?? '') ?? DateTime.now())}",
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
