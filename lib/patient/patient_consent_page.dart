import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientConsentPage extends StatelessWidget {
  final String patientId;

  const PatientConsentPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Sharing Consent"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('data_requests')
            .where('patientId', isEqualTo: patientId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No data sharing requests",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              return _ConsentCard(
                requestId: doc.id,
                fromHospitalId: data['fromHospitalId'],
                toHospitalId: data['toHospitalId'],
                otp: data['otp'],
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// ================= CONSENT CARD =========================
// =======================================================

class _ConsentCard extends StatelessWidget {
  final String requestId;
  final String fromHospitalId;
  final String toHospitalId;
  final String otp;

  const _ConsentCard({
    required this.requestId,
    required this.fromHospitalId,
    required this.toHospitalId,
    required this.otp,
  });

  Future<String> _getHospitalName(String hospitalId) async {
    final doc = await FirebaseFirestore.instance
        .collection('accounts')
        .doc(hospitalId)
        .get();

    final data = doc.data() as Map<String, dynamic>?;
    return data?['hospitalName'] ?? hospitalId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        _getHospitalName(fromHospitalId),
        _getHospitalName(toHospitalId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }

        final fromHospitalName = snapshot.data![0];
        final toHospitalName = snapshot.data![1];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- TITLE --------
                const Text(
                  "Medical Data Transfer Request",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // -------- MESSAGE --------
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: "Your medical records from "),
                      TextSpan(
                        text: fromHospitalName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: " are being shared with "),
                      TextSpan(
                        text: toHospitalName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // -------- OTP DISPLAY (NEW) --------
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.purple.shade100,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "OTP: $otp",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Please enter the above OTP to approve this data sharing request.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // -------- ACTIONS --------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('data_requests')
                            .doc(requestId)
                            .update({
                          "status": "rejected",
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Request rejected"),
                          ),
                        );
                      },
                      child: const Text(
                        "Reject",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showOtpDialog(
                          context,
                          requestId,
                          otp,
                        );
                      },
                      child: const Text("Proceed"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= OTP DIALOG =================

  void _showOtpDialog(
      BuildContext parentContext, // 👈 IMPORTANT
      String requestId,
      String correctOtp,
      ) {
    final otpController = TextEditingController();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- TITLE --------
                const Text(
                  "OTP Verification",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Enter the OTP provided by the hospital to approve data sharing.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // -------- OTP INPUT --------
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "OTP",
                    counterText: "",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // -------- ACTIONS --------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      onPressed: () async {
                        if (otpController.text.trim() != correctOtp) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid OTP"),
                            ),
                          );
                          return;
                        }

                        // -------- UPDATE FIRESTORE --------
                        await FirebaseFirestore.instance
                            .collection('data_requests')
                            .doc(requestId)
                            .update({
                          "status": "approved",
                        });

                        Navigator.of(dialogContext).pop(); // ✅ CLOSE DIALOG

                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text("Consent approved successfully"),
                          ),
                        );
                      },
                      child: const Text(
                        "Verify",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

