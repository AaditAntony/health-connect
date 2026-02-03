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

    await FirebaseFirestore.instance.collection('patients').add({
      "name": nameController.text.trim(),
      "age": ageController.text.trim(),
      "gender": gender,
      "bloodGroup": bloodGroup,
      "phone": phoneController.text.trim(),
      "email": emailController.text.trim(),

      // 🔒 IMPORTANT: hospital isolation
      "hospitalId": widget.hospitalId,

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
                decoration: const InputDecoration(
                  labelText: "Patient Name",
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                ),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => gender = v!),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: bloodGroup,
                decoration: const InputDecoration(
                  labelText: "Blood Group",
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
              const SizedBox(height: 10),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email (optional)",
                ),
              ),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: savePatient,
                  child: const Text("Save Patient"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
