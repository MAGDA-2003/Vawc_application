import 'package:flutter/material.dart';

class EditReportPage extends StatefulWidget {
  final Map<String, dynamic> report;

  const EditReportPage({
    super.key,
    required this.report,
    required Null Function(dynamic updatedReport) onSave,
  });

  @override
  State<EditReportPage> createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  late TextEditingController victim;
  late TextEditingController victimContact;
  late TextEditingController victimEmail;
  late TextEditingController victimAddress;
  late TextEditingController perpetratorName;
  late TextEditingController perpetratorContact;
  late TextEditingController perpetratorEmail;
  late TextEditingController perpetratorAddress;
  late TextEditingController relationship;
  late TextEditingController type;
  late TextEditingController details;
  late TextEditingController location;
  late TextEditingController date;
  late TextEditingController time;
  late TextEditingController status;

  bool get isEditable {
    final currentStatus = widget.report["status"] ?? "Pending Review";
    //  These statuses CANNOT be edited
    return !(currentStatus == "Ongoing Case" ||
        currentStatus == "Scheduled for Action" ||
        currentStatus == "Case Closed");
  }

  @override
  void initState() {
    super.initState();
    victim = TextEditingController(text: widget.report["victim"]);
    victimContact = TextEditingController(text: widget.report["victimContact"]);
    victimEmail = TextEditingController(text: widget.report["victimEmail"]);
    victimAddress = TextEditingController(text: widget.report["victimAddress"]);
    perpetratorName = TextEditingController(
      text: widget.report["perpetratorName"],
    );
    perpetratorContact = TextEditingController(
      text: widget.report["perpetratorContact"],
    );
    perpetratorEmail = TextEditingController(
      text: widget.report["perpetratorEmail"],
    );
    perpetratorAddress = TextEditingController(
      text: widget.report["perpetratorAddress"],
    );
    relationship = TextEditingController(text: widget.report["relationship"]);
    type = TextEditingController(text: widget.report["type"]);
    details = TextEditingController(text: widget.report["details"]);
    location = TextEditingController(text: widget.report["location"]);
    date = TextEditingController(text: widget.report["date"]);
    time = TextEditingController(text: widget.report["time"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Report"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isEditable)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This report can no longer be edited because it is already assigned or closed.",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            buildField("Victim Name", victim),
            buildField("Victim Contact", victimContact),
            buildField("Victim Email", victimEmail),
            buildField("Victim Address", victimAddress),
            buildField("Perpetrator Name", perpetratorName),
            buildField("Perpetrator Contact", perpetratorContact),
            buildField("Perpetrator Email", perpetratorEmail),
            buildField("Perpetrator Address", perpetratorAddress),
            buildField("Relationship", relationship),
            buildField("Incident Type", type),
            buildField("Details", details, maxLines: 3),
            buildField("Location", location),
            buildField("Date", date),
            buildField("Time", time),
            buildField("Status", status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isEditable
                  ? () {
                      final updatedReport = {
                        ...widget.report,
                        "victim": victim.text,
                        "victimContact": victimContact.text,
                        "victimEmail": victimEmail.text,
                        "victimAddress": victimAddress.text,
                        "perpetratorName": perpetratorName.text,
                        "perpetratorContact": perpetratorContact.text,
                        "perpetratorEmail": perpetratorEmail.text,
                        "perpetratorAddress": perpetratorAddress.text,
                        "relationship": relationship.text,
                        "type": type.text,
                        "details": details.text,
                        "location": location.text,
                        "date": date.text,
                        "time": time.text,
                        "status": status.text,
                      };
                      Navigator.pop(context, updatedReport);
                    }
                  : null, // disables button
              style: ElevatedButton.styleFrom(
                backgroundColor: isEditable
                    ? const Color.fromARGB(255, 124, 111, 148)
                    : Colors.grey.shade400,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: isEditable,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
