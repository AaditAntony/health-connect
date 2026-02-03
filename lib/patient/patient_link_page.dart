import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum LinkMethod { phone, patientId }

class PatientLinkPage extends StatefulWidget {
  const PatientLinkPage({super.key});

  @override
  State<PatientLinkPage> createState() => _PatientLinkPageState();
}

class _PatientLinkPageState extends State<PatientLinkPage> {
  final phoneController = TextEditingController();
  final patientIdController = TextEditingController();

  LinkMethod method = LinkMethod.phone;
  bool loading = false;

  Future<void> linkPatient() async {
    setState(() => loading = true);

    final authUid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot? patientDoc;

    try {
      // -------- LINK USING PHONE --------
      if (method == LinkMethod.phone) {
        if (phoneController.text.trim().isEmpty) {
          throw "Please enter phone number";
        }

        final query = await FirebaseFirestore.instance
            .collection('patients')
            .where('phone', isEqualTo: phoneController.text.trim())
            .get();

        if (query.docs.length != 1) {
          throw "Patient record not found or multiple records found";
        }

        patientDoc = query.docs.first;
      }

      // -------- LINK USING PATIENT ID --------
      if (method == LinkMethod.patientId) {
        if (patientIdController.text.trim().isEmpty) {
          throw "Please enter Patient ID";
        }

        final doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientIdController.text.trim())
            .get();

        if (!doc.exists) {
          throw "Invalid Patient ID";
        }

        patientDoc = doc;
      }

      // -------- SAVE LINK (ONE TIME) --------
      await FirebaseFirestore.instance
          .collection('patient_users')
          .doc(authUid)
          .set({
        "authUid": authUid,
        "patientId": patientDoc!.id,
        "linkedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medical record linked successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link Medical Record")),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Link your medical record",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -------- NEW RADIO GROUP (NO DEPRECATION) --------
                  RadioGroup<LinkMethod>(
                    groupValue: method,
                    onChanged: (value) {
                      setState(() => method = value!);
                    },
                    child: Column(
                      children: const [
                        RadioListTile(
                          value: LinkMethod.phone,
                          title: Text("Link using Phone Number"),
                        ),
                        RadioListTile(
                          value: LinkMethod.patientId,
                          title: Text("Link using Patient ID (from bill)"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // -------- INPUT FIELD --------
                  if (method == LinkMethod.phone)
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                      ),
                    ),

                  if (method == LinkMethod.patientId)
                    TextField(
                      controller: patientIdController,
                      decoration: const InputDecoration(
                        labelText: "Patient ID",
                        hintText: "Example: AbC123Xyz",
                        border: OutlineInputBorder(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // -------- ACTION --------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : linkPatient,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          loading ? "Linking..." : "Link Record",
                        ),
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
