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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          const Text(
            "Request Patient Data",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Generate an OTP and request patient consent to access medical records.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 28),

          // ================= FORM CARD =================
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // -------- PATIENT ID --------
                  TextField(
                    controller: patientIdController,
                    decoration: InputDecoration(
                      labelText: "Patient ID",
                      hintText: "Enter Patient ID from bill",
                      prefixIcon: const Icon(
                        Icons.badge,
                        color: Color(0xFF7C3AED),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // -------- HOSPITAL DROPDOWN --------
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('accounts')
                        .where('role', isEqualTo: 'hospital')
                        .where('approved', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }

                      final hospitals = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: selectedHospitalId,
                        decoration: InputDecoration(
                          labelText: "Select Target Hospital",
                          prefixIcon: const Icon(
                            Icons.local_hospital,
                            color: Color(0xFF7C3AED),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: hospitals.map((doc) {
                          final data =
                          doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child:
                            Text(data['hospitalName'] ?? doc.id),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedHospitalId = value);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // -------- CREATE BUTTON --------
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : createRequest,
                      icon: const Icon(Icons.vpn_key),
                      label: Text(
                        loading
                            ? "Creating Request..."
                            : "Generate OTP & Request Consent",
                        style:
                        const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ================= OTP DISPLAY =================
          if (generatedOtp != null)
            Card(
              elevation: 3,
              color: const Color(0xFFF3E8FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Generated OTP",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        generatedOtp!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Share this OTP securely with the patient to confirm consent.",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
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
