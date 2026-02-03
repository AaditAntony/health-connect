import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientLinkPage extends StatefulWidget {
  const PatientLinkPage({super.key});

  @override
  State<PatientLinkPage> createState() => _PatientLinkPageState();
}

class _PatientLinkPageState extends State<PatientLinkPage> {
  final phoneController = TextEditingController();
  bool loading = false;

  Future<void> linkPatient() async {
    setState(() => loading = true);

    final authUid = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection('patients')
        .where('phone', isEqualTo: phoneController.text.trim())
        .get();

    if (query.docs.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Patient record not found or multiple records found"),
        ),
      );
      setState(() => loading = false);
      return;
    }

    final patientDoc = query.docs.first;

    await FirebaseFirestore.instance
        .collection('patient_users')
        .doc(authUid)
        .set({
      "authUid": authUid,
      "patientId": patientDoc.id,
      "phone": phoneController.text.trim(),
      "linkedAt": Timestamp.now(),
    });

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link Medical Record")),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter the phone number used during hospital registration",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                    const InputDecoration(labelText: "Phone Number"),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : linkPatient,
                    child: const Text("Link Record"),
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
