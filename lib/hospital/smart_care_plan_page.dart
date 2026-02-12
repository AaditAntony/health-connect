import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartCarePlanPage extends StatefulWidget {
  const SmartCarePlanPage({super.key});

  @override
  State<SmartCarePlanPage> createState() => _SmartCarePlanPageState();
}

class _SmartCarePlanPageState extends State<SmartCarePlanPage> {
  final amountController = TextEditingController();
  final doctorCountController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();

  List<TextEditingController> doctorNameControllers = [];
  List<TextEditingController> departmentControllers = [];

  String selectedDurationType = "days"; // minutes / hours / days
  bool loading = false;

  @override
  void initState() {
    super.initState();
    doctorCountController.addListener(_updateDoctorFields);
  }

  // ---------------- DYNAMIC DOCTOR FIELDS ----------------

  void _updateDoctorFields() {
    final count = int.tryParse(doctorCountController.text) ?? 0;
    if (count < 0) return;

    setState(() {
      doctorNameControllers =
          List.generate(count, (_) => TextEditingController());
      departmentControllers =
          List.generate(count, (_) => TextEditingController());
    });
  }

  // ---------------- SAVE PLAN ----------------

  Future<void> savePlan() async {
    final count = int.tryParse(doctorCountController.text) ?? 0;
    final durationValue = int.tryParse(durationController.text);

    if (amountController.text.isEmpty ||
        doctorCountController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        durationValue == null ||
        durationValue <= 0 ||
        doctorNameControllers.length != count) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields correctly")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final hospitalId = FirebaseAuth.instance.currentUser!.uid;

      List<Map<String, dynamic>> doctors = [];

      for (int i = 0; i < count; i++) {
        if (doctorNameControllers[i].text.isEmpty ||
            departmentControllers[i].text.isEmpty) {
          throw "Fill all doctor details";
        }

        doctors.add({
          "name": doctorNameControllers[i].text.trim(),
          "department": departmentControllers[i].text.trim(),
        });
      }

      // -------- CALCULATE EXPIRY --------
      DateTime now = DateTime.now();
      DateTime expiry;

      if (selectedDurationType == "minutes") {
        expiry = now.add(Duration(minutes: durationValue));
      } else if (selectedDurationType == "hours") {
        expiry = now.add(Duration(hours: durationValue));
      } else {
        expiry = now.add(Duration(days: durationValue));
      }

      final data = {
        "amount": int.parse(amountController.text.trim()),
        "doctorCount": count,
        "description": descriptionController.text.trim(),
        "doctors": doctors,
        "createdByHospitalId": hospitalId,
        "createdAt": Timestamp.fromDate(now),
        "expiresAt": Timestamp.fromDate(expiry),
        "status": "active",
      };

      await FirebaseFirestore.instance
          .collection('smartcareplans')
          .add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SmartCarePlan created successfully")),
      );

      // -------- CLEAR FORM AFTER SAVE --------
      amountController.clear();
      doctorCountController.clear();
      descriptionController.clear();
      durationController.clear();
      doctorNameControllers.clear();
      departmentControllers.clear();

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("SmartCarePlan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: SizedBox(
            width: 700,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // -------- HEADER --------
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF5B21B6),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "SmartCarePlan",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Create subscription plans for your patients",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _input("Monthly Amount (₹)"),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: doctorCountController,
                      keyboardType: TextInputType.number,
                      decoration: _input("Number of Doctors"),
                    ),

                    const SizedBox(height: 16),

                    // -------- DURATION SECTION --------
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: _input("Plan Duration"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: selectedDurationType,
                          items: const [
                            DropdownMenuItem(
                              value: "minutes",
                              child: Text("Minutes"),
                            ),
                            DropdownMenuItem(
                              value: "hours",
                              child: Text("Hours"),
                            ),
                            DropdownMenuItem(
                              value: "days",
                              child: Text("Days"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedDurationType = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // -------- DYNAMIC DOCTORS --------
                    for (int i = 0; i < doctorNameControllers.length; i++)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Doctor ${i + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: doctorNameControllers[i],
                            decoration: _input("Doctor Name"),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: departmentControllers[i],
                            decoration: _input("Department"),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: _input("Plan Description"),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : savePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          loading ? "Saving..." : "Create Plan",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
