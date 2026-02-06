import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_connect/web/hospital_login_page.dart';

class HospitalVerificationPage extends StatelessWidget {
  const HospitalVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SizedBox(
          width: 520,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('accounts')
                  .doc(hospitalId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final approved = data['approved'] == true;

                // Safety: if approved, AuthWrapper will redirect
                if (approved) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // -------- ICON --------
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_top,
                          size: 40,
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // -------- TITLE --------
                      const Text(
                        "Verification in Progress",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------- DESCRIPTION --------
                      const Text(
                        "Your hospital details have been successfully submitted.\n"
                        "Our admin team is currently reviewing your information.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // -------- INFO BOX --------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "What happens next?",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "• Admin will verify your hospital details\n"
                              "• Once approved, you will gain full access\n"
                              "• You can then manage patients and treatments",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // -------- HOSPITAL SUMMARY --------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Submitted Details",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Hospital: ${data['hospitalName'] ?? ''}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "District: ${data['district'] ?? ''}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "Established: ${data['establishedYear'] ?? ''}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // -------- LOGOUT --------
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HospitalLoginPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text("Logout"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
