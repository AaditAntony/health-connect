import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  String gender = "Male";
  String bloodGroup = "O+";

  Future<void> submit() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('patients').add({
      "name": nameController.text.trim(),
      "age": ageController.text.trim(),
      "gender": gender,
      "bloodGroup": bloodGroup,
      "phone": phoneController.text.trim(),
      "email": emailController.text.trim(),
      "hospitalId": uid,
      "createdAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Add Patient"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 520,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Patient Information",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration:
                    const InputDecoration(labelText: "Patient Name"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Age"),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(labelText: "Gender"),
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (v) => setState(() => gender = v!),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: bloodGroup,
                    decoration: const InputDecoration(labelText: "Blood Group"),
                    items: const [
                      DropdownMenuItem(value: "O+", child: Text("O+")),
                      DropdownMenuItem(value: "O-", child: Text("O-")),
                      DropdownMenuItem(value: "A+", child: Text("A+")),
                      DropdownMenuItem(value: "A-", child: Text("A-")),
                      DropdownMenuItem(value: "B+", child: Text("B+")),
                      DropdownMenuItem(value: "B-", child: Text("B-")),
                      DropdownMenuItem(value: "AB+", child: Text("AB+")),
                      DropdownMenuItem(value: "AB-", child: Text("AB-")),
                    ],
                    onChanged: (v) => setState(() => bloodGroup = v!),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                    const InputDecoration(labelText: "Phone Number"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emailController,
                    decoration:
                    const InputDecoration(labelText: "Email (optional)"),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: Text("Save Patient",style: TextStyle(color: Colors.white),),
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
