import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'viewreport_page.dart';
import 'login_page.dart';
import 'notification_page.dart';

class ReportIncidentPage extends StatefulWidget {
  final int currentUserId; // make it int
  const ReportIncidentPage({super.key, required this.currentUserId});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  bool immediateResponse = false;
  File? _image;
  final picker = ImagePicker();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final victim = TextEditingController();
  final details = TextEditingController();
  final location = TextEditingController();
  final date = TextEditingController();
  final time = TextEditingController();
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

  String? selectedIncidentType;
  List<Map<String, dynamic>> reports = [];

  void _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        date.text = DateFormat('y-MM-dd').format(picked);
      });
    }
  }

  void _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        time.text = DateFormat('h:mm a').format(dt);
      });
    }
  }

  void submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirm submission
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

    if (confirm != true) return;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://192.168.100.17/vawc_php/report.php"),
      );

      request.fields.addAll({
        'user_id': widget.currentUserId.toString(),
        "victim": victim.text,
        "type": selectedIncidentType ?? "Not specified",
        "details": details.text,
        "location": location.text,
        "date": date.text,
        "time": time.text,
        "contact": contact.text,
        "status": "Pending Review",
        "victimContact": victimContact.text,
        "victimEmail": victimEmail.text,
        "victimAddress": victimAddress.text,
        "perpetratorName": perpetratorName.text,
        "perpetratorContact": perpetratorContact.text,
        "perpetratorAddress": perpetratorAddress.text,
        "perpetratorEmail": perpetratorEmail.text,
        "relationship": relationship.text,
      });

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _image!.path),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print(responseBody); // <-- See what PHP actually returns

      final data = jsonDecode(responseBody);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report submitted successfully!")),
        );

        //  Clear fields after submit
        setState(() {
          victim.clear();
          details.clear();
          location.clear();
          date.clear();
          time.clear();
          contact.clear();
          victimContact.clear();
          victimEmail.clear();
          victimAddress.clear();
          perpetratorName.clear();
          perpetratorContact.clear();
          perpetratorAddress.clear();
          perpetratorEmail.clear();
          relationship.clear();
          _image = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
      }
    } catch (e) {
      print("Error submitting report: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    }
  }

  void confirmAndCall911() async {
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

    if (confirmCall == true) {
      await makePhoneCall('(02) 8808 2722');
    }
  }

  Future<void> makePhoneCall(String number) async {
    final Uri phoneUri = Uri.parse('tel:$number');
    if (!await launchUrl(phoneUri)) {
      debugPrint('Could not launch dialer for $number');
    }
  }

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
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report an Incident"),
        backgroundColor: Colors.blueAccent,
        actions: [
          //Notifications Icon
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (context) =>
                      NotificationPage(userId: widget.currentUserId),
                ),
              );
            },
          ),

          //View Reports Icon
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: "View Reports",
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewReportsPage(userId: widget.currentUserId),
                ),
              );
            },
          ),

          // Logout Icon
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log Out",
            onPressed: logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 226, 235, 245),
              Color.fromARGB(255, 145, 187, 234),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(7),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: const Color.fromARGB(
                      255,
                      254,
                      247,
                      243,
                    ), // light background
                    elevation: 5,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 30,
                        left: 11,
                        right: 11,
                        bottom: 40,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Incident Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),

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
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) => setState(() {
                              selectedIncidentType = value;
                            }),
                            validator: (value) => value == null
                                ? "Please select an incident type"
                                : null,
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
                            validator: (v) =>
                                v!.isEmpty ? "Please enter the location" : null,
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
                                  validator: (v) =>
                                      v!.isEmpty ? "Select date" : null,
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
                                  validator: (v) =>
                                      v!.isEmpty ? "Select time" : null,
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
                            validator: (v) =>
                                v!.isEmpty ? "Please provide details" : null,
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(thickness: 2),
                  Card(
                    color: const Color.fromARGB(
                      255,
                      254,
                      247,
                      243,
                    ), // light background
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 30,
                        left: 11,
                        right: 11,
                        bottom: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Victim's Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: victim,
                            decoration: const InputDecoration(
                              labelText: "Victim's Name",
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Enter victim name" : null,
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
                            validator: (v) =>
                                v!.isEmpty ? "Enter contact number" : null,
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
                            validator: (v) =>
                                v!.isEmpty ? "Enter Victim's Email" : null,
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
                            validator: (v) =>
                                v!.isEmpty ? "Enter Victim's Address" : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 2),
                  Card(
                    color: const Color.fromARGB(
                      255,
                      254,
                      247,
                      243,
                    ), // light background
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 30,
                        left: 11,
                        right: 11,
                        bottom: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Perpetrator Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: perpetratorName,
                            decoration: const InputDecoration(
                              labelText: "Perpetrator's Name",
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Perpetrator's Name" : null,
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
                            validator: (v) => v!.isEmpty
                                ? "Perpetrator's Contact Number"
                                : null,
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
                            validator: (v) => v!.isEmpty
                                ? "Enter Perpetrator's Address"
                                : null,
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
                            validator: (v) => v!.isEmpty
                                ? "Enter Relationship to Perpetrator"
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: const Color.fromARGB(
                      255,
                      254,
                      247,
                      243,
                    ), // light background
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 17,
                        left: 11,
                        right: 11,
                        bottom: 17,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Need Immediate Assistance",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(
                              radioTheme: RadioThemeData(
                                fillColor: WidgetStateProperty.all(
                                  Color(0xFF0D62C4),
                                ), // your blue
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Yes"),
                                    value: true,
                                    groupValue: immediateResponse,
                                    onChanged: (value) {
                                      setState(() {
                                        immediateResponse = value!;
                                      });
                                      if (value == true) {
                                        confirmAndCall911(); // trigger emergency call dialog
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("No"),
                                    value: false,
                                    groupValue: immediateResponse,
                                    onChanged: (value) {
                                      setState(() {
                                        immediateResponse = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: submitReport,
                      icon: const Icon(Icons.send),
                      label: const Text("Submit Report"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 2, 63, 244),
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(body: Center(child: Text("Feature coming soon")));
}
