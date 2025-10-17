import 'dart:io';
import 'package:intl/intl.dart';

import 'viewreport_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  bool immediateResponse = false;
  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final picker = ImagePicker();
  final victim = TextEditingController();
  final type = TextEditingController();
  final details = TextEditingController();
  final location = TextEditingController();
  final time = TextEditingController();
  final date = TextEditingController();
  final contact = TextEditingController();
  final status = TextEditingController();
  final victimContact = TextEditingController();
  final victimEmail = TextEditingController();
  final victimAddress = TextEditingController();
  final perpetratorName = TextEditingController();
  final perpetratorContact = TextEditingController();
  final perpetratorAddress = TextEditingController();
  final perpetratorEmail = TextEditingController();
  final relationship = TextEditingController();

  void _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _pickDate(BuildContext context) async {
    date.text = DateFormat('y-MM-dd').format(selectedDate);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _pickTime(BuildContext context) async {
    time.text = DateFormat('h:mm a').format(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  List<Map<String, String>> reports = [];

  String? selectedIncidentType;

  void confirmAndCall911() async {
    // Ask for confirmation
    bool? confirmCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Call"),
        content: const Text(
          "Are you sure you want to call an emergency for immediate assistance?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Call Barangay"),
          ),
        ],
      ),
    );

    //If confirmed, make the call
    if (confirmCall == true) {
      await makePhoneCall('(02) 8808 2722');
    }
  }

  //Separate phone call function
  Future<void> makePhoneCall(String number) async {
    final Uri phoneUri = Uri.parse('tel:$number');

    if (!await launchUrl(phoneUri)) {
      debugPrint('Could not launch dialer for $number');
    }
  }

  void submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return; // stop if form is invalid
    }

    //Confirm submission
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text(
          'Are you sure you want to submit this report?\n'
          'Please ensure all details are correct.\n'
          'You will no longer be able to edit these details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return; // stop if user cancels

    //Save the report
    reports.add({
      "victim": victim.text,
      "type": selectedIncidentType ?? "Not specified",
      "details": details.text,
      "location": location.text,
      "date": date.text,
      "time": time.text,
      "contact": contact.text,
      "timestamp": DateTime.now().toString(),
      "status": status.text.isNotEmpty ? status.text : "Pending Review",
      "imagePath": _image?.path ?? "",
      "immediateResponse": immediateResponse ? "Yes" : "No",
      "victimContact": victimContact.text,
      "victimEmail": victimEmail.text,
      "victimAddress": victimAddress.text,
      "perpetratorName": perpetratorName.text,
      "perpetratorContact": perpetratorContact.text,
      "perpetratorAddress": perpetratorAddress.text,
      "perpetratorEmail": perpetratorEmail.text,
      "relationship": relationship.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Report submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    //Step 3: Clear all fields
    victim.clear();
    details.clear();
    location.clear();
    selectedIncidentType = null;
    date.clear();
    time.clear();
    _image = null;
    contact.clear();
    immediateResponse = false;
    victimContact.clear();
    victimEmail.clear();
    victimAddress.clear();
    perpetratorName.clear();
    perpetratorContact.clear();
    perpetratorAddress.clear();
    perpetratorEmail.clear();
    relationship.clear();

    setState(() {});

    //Show emergency assistance dialog BEFORE navigating
    bool? needHelp = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Assistance"),
        content: const Text(
          "Do you need to call your barangay for immediate help?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Call VAWC"),
          ),
        ],
      ),
    );

    if (needHelp == true) {
      await makePhoneCall('(02) 8808 2722'); // change to your hotline
    }

    // ✅ Step 5: Go to the reports page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewReportsPage(reports: reports)),
    );
  }

  //  Logout with confirmation dialog
  void logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text(
          "Are you sure you want to log out? Make sure to save your work.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // confirm
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 147, 167, 213),
      appBar: AppBar(
        title: const Text("Report an Incident", style: TextStyle(fontSize: 25)),
        backgroundColor: const Color.fromARGB(255, 226, 123, 38),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: "View Reports",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewReportsPage(reports: reports),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log Out",
            onPressed: logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Incident Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedIncidentType,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  labelText: "Type of Incident",
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                      "Physical Abuse",
                      "Sexual Abuse",
                      "Psychological Abuse",
                      "Emotional Abuse",
                      "Economic Abuse",
                    ].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedIncidentType = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Please select an incident type" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: location,
                decoration: const InputDecoration(
                  labelText: "Location of Incident",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter the location" : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: date,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Date",
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _pickDate(context),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Select date" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: time,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Time",
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _pickTime(context),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Select time" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: details,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Details of Incident",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please provide details" : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image,
                        color: Color.fromARGB(255, 241, 123, 123),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _image == null
                            ? "Attach Image"
                            : "Image Selected: ${_image!.path.split('/').last}",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const Text(
                "Personal Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Victim Info
              TextFormField(
                controller: victim,
                decoration: const InputDecoration(
                  labelText: "Victim's Name",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter victim name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: victimContact,
                decoration: const InputDecoration(
                  labelText: "Victim's Contact",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter contact number" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: victimEmail,
                decoration: const InputDecoration(
                  labelText: "Victim's Email",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? " Enter Victim's Email" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: victimAddress,
                decoration: const InputDecoration(
                  labelText: "Victim's Address",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? " Enter Victim's Address" : null,
              ),

              const SizedBox(height: 20),
              const Text(
                "Perpetrator Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: perpetratorName,
                decoration: const InputDecoration(
                  labelText: "Perpetrator's Name",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Perpetrator's Name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: perpetratorContact,
                decoration: const InputDecoration(
                  labelText: "Perpetrator's Contact Number",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Perpetrator's Contact Number" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: perpetratorEmail,
                decoration: const InputDecoration(
                  labelText: "Perpetrator's Email",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: perpetratorAddress,
                decoration: const InputDecoration(
                  labelText: "Perpetrator's Address",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter Perpetrator's Address" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: relationship,
                decoration: const InputDecoration(
                  labelText: "Relationship to Perpetrator",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty
                    ? "Enter Relationship to Perpertrator"
                    : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text("Need Immediate Assistance"),
                  Switch(
                    value: immediateResponse,
                    onChanged: (value) {
                      setState(() {
                        immediateResponse = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: submitReport,
                  icon: const Icon(Icons.send),
                  label: const Text("Submit Report"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(500, 50),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
