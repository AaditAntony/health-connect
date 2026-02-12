import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientSmartCarePlanPage extends StatelessWidget {
  const PatientSmartCarePlanPage({super.key});

  Future<void> activatePlan(
      BuildContext context,
      String planId,
      Map<String, dynamic> planData,
      ) async {
    final authUid = FirebaseAuth.instance.currentUser!.uid;

    // Get linked patientId
    final patientDoc = await FirebaseFirestore.instance
        .collection('patient_users')
        .doc(authUid)
        .get();

    final String patientId = patientDoc['patientId'];

    // Prevent duplicate activation
    final existing = await FirebaseFirestore.instance
        .collection('patient_plans')
        .where('patientId', isEqualTo: patientId)
        .where('planId', isEqualTo: planId)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plan already activated")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('patient_plans').add({
      "patientId": patientId,
      "planId": planId,
      "hospitalId": planData['createdByHospitalId'],
      "amount": planData['amount'],
      "activatedAt": Timestamp.now(),
      "status": "active",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your SmartCarePlan is now activated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("SmartCare Plans"),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('smartcareplans')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data!.docs;

          if (plans.isEmpty) {
            return const Center(
              child: Text(
                "No plans available",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final doc = plans[index];
              final data = doc.data() as Map<String, dynamic>;
              final List doctors = data['doctors'] ?? [];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEDE9FE),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "SmartCarePlan",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // PRICE
                      Text(
                        "₹ ${data['amount']} / Month",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "${data['doctorCount']} Doctor Visits Included",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 16),

                      // DESCRIPTION
                      Text(
                        data['description'] ?? "",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      const Divider(height: 24),

                      // DOCTORS
                      const Text(
                        "Included Specialists",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...doctors.map((doc) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${doc['name']} • ${doc['department']}",
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              activatePlan(context, doc.id, data),
                          child: const Text(
                            "Activate Plan",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
