import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataRequestsTab extends StatefulWidget {
  const DataRequestsTab({super.key});

  @override
  State<DataRequestsTab> createState() => _DataRequestsTabState();
}

class _DataRequestsTabState extends State<DataRequestsTab> {
  final patientIdController = TextEditingController();

  bool loading = false;
  String? generatedOtp;

  String? selectedHospitalId;

  // -------- OTP GENERATOR --------
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // -------- CREATE DATA REQUEST --------
  Future<void> createRequest() async {
    if (patientIdController.text.trim().isEmpty ||
        selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final hospitalId = FirebaseAuth.instance.currentUser!.uid;

      // 🔹 Fetch hospital name + seal
      final hospitalDoc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(hospitalId)
          .get();

      final String hospitalName = hospitalDoc['hospitalName'];
      final String sealSignBase64 = hospitalDoc['sealSignBase64'];

      final otp = _generateOtp();

      await FirebaseFirestore.instance.collection('data_requests').add({
        "fromHospitalId": hospitalId,
        "fromHospitalName": hospitalName,
        "toHospitalId": selectedHospitalId,
        "patientId": patientIdController.text.trim(),
        "otp": otp,
        "sealSignBase64": sealSignBase64,
        "status": "pending",
        "createdAt": Timestamp.now(),
      });

      setState(() {
        generatedOtp = otp;
        patientIdController.clear();
        selectedHospitalId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data request created successfully"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Request Patient Data",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select an approved hospital and generate an OTP "
                "to request patient consent.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 24),

          // -------- PATIENT ID --------
          TextField(
            controller: patientIdController,
            decoration: const InputDecoration(
              labelText: "Patient ID",
              hintText: "From patient bill",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // -------- APPROVED HOSPITAL DROPDOWN --------
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('accounts')
                .where('role', isEqualTo: 'hospital')
                .where('approved', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final hospitals = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                value: selectedHospitalId,
                decoration: const InputDecoration(
                  labelText: "Select Target Hospital",
                  border: OutlineInputBorder(),
                ),
                items: hospitals.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      data['hospitalName'] ?? doc.id,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedHospitalId = value);
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // -------- CREATE BUTTON --------
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: loading ? null : createRequest,
              child: Text(
                loading ? "Creating..." : "Create Request & Generate OTP",
              ),
            ),
          ),

          const SizedBox(height: 24),

          // -------- OTP DISPLAY --------
          if (generatedOtp != null)
            Card(
              color: Colors.green.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Generated OTP",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      generatedOtp!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Share this OTP with the patient for verification.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
