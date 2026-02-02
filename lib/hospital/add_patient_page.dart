import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/responsive.dart';

class AddPatientPage extends StatefulWidget {
  final String hospitalId;

  const AddPatientPage({super.key, required this.hospitalId});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final problemController = TextEditingController();

  bool isLoading = false;

  Future<void> addPatient() async {
    setState(() => isLoading = true);

    await FirebaseFirestore.instance.collection('patients').add({
      "name": nameController.text.trim(),
      "age": ageController.text.trim(),
      "problem": problemController.text.trim(),
      "hospitalId": widget.hospitalId,
      "createdAt": Timestamp.now(),
    });

    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Patient")),
      body: ResponsiveWrapper(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Patient Name"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: problemController,
                decoration:
                const InputDecoration(labelText: "Health Problem"),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : addPatient,
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
