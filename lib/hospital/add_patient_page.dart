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

  Future<void> savePatient() async {
    if (nameController.text.isEmpty || ageController.text.isEmpty) return;

    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('patients').add({
      "name": nameController.text.trim(),
      "age": ageController.text.trim(),
      "gender": gender,
      "bloodGroup": bloodGroup,
      "phone": phoneController.text.trim(),
      "email": emailController.text.trim(),

      // 🔒 CRITICAL FIELD
      "hospitalId": hospitalId,

      "createdAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Patient")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Patient Name"),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
              ),
              DropdownButtonFormField(
                value: gender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => gender = v!),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              DropdownButtonFormField(
                value: bloodGroup,
                items: const [
                  DropdownMenuItem(value: "O+", child: Text("O+")),
                  DropdownMenuItem(value: "O-", child: Text("O-")),
                  DropdownMenuItem(value: "A+", child: Text("A+")),
                  DropdownMenuItem(value: "B+", child: Text("B+")),
                  DropdownMenuItem(value: "AB+", child: Text("AB+")),
                ],
                onChanged: (v) => setState(() => bloodGroup = v!),
                decoration: const InputDecoration(labelText: "Blood Group"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: savePatient,
                child: const Text("Save Patient"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
