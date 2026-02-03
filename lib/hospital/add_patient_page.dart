import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPatientPage extends StatefulWidget {
  final String hospitalId;

  const AddPatientPage({super.key, required this.hospitalId});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController();

  String gender = "Male";
  String bloodGroup = "O+";

  Future<void> savePatient() async {
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    // 1️⃣ Save patient
    final patientRef =
    await FirebaseFirestore.instance.collection('patients').add({
      "name": nameController.text.trim(),
      "age": ageController.text.trim(),
      "gender": gender,
      "bloodGroup": bloodGroup,
      "phone": phoneController.text.trim(),
      "email": emailController.text.trim(),
      "hospitalId": widget.hospitalId,
      "createdAt": Timestamp.now(),
    });

    // 2️⃣ Save initial treatment (optional but useful)
    if (diagnosisController.text.isNotEmpty ||
        treatmentController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('treatments').add({
        "patientId": patientRef.id,
        "hospitalId": widget.hospitalId,
        "diagnosis": diagnosisController.text.trim(),
        "treatmentPlan": treatmentController.text.trim(),
        "createdAt": Timestamp.now(),
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add New Patient",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---------- BASIC INFO ----------
                  const Text(
                    "Patient Information",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Age",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField(
                          value: gender,
                          decoration: const InputDecoration(
                            labelText: "Gender",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: "Male", child: Text("Male")),
                            DropdownMenuItem(
                                value: "Female", child: Text("Female")),
                            DropdownMenuItem(
                                value: "Other", child: Text("Other")),
                          ],
                          onChanged: (v) => setState(() => gender = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField(
                    value: bloodGroup,
                    decoration: const InputDecoration(
                      labelText: "Blood Group",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "O+", child: Text("O+")),
                      DropdownMenuItem(value: "O-", child: Text("O-")),
                      DropdownMenuItem(value: "A+", child: Text("A+")),
                      DropdownMenuItem(value: "A-", child: Text("A-")),
                      DropdownMenuItem(value: "B+", child: Text("B+")),
                      DropdownMenuItem(value: "AB+", child: Text("AB+")),
                    ],
                    onChanged: (v) => setState(() => bloodGroup = v!),
                  ),

                  const SizedBox(height: 24),

                  // ---------- CONTACT ----------
                  const Text(
                    "Contact Information",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- MEDICAL ----------
                  const Text(
                    "Medical Information",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: diagnosisController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Diagnosis",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: treatmentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Treatment Plan",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: savePatient,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text("Save Patient"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
