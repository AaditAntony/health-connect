import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPatientRecordsPage extends StatelessWidget {
  const SharedPatientRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared Patient Records"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('data_requests')
            .where('toHospitalId', isEqualTo: hospitalId)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No shared records available",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;

              return _SharedPatientCard(
                patientId: data['patientId'],
                fromHospitalId: data['fromHospitalId'],
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// ================= SHARED PATIENT CARD =================
// =======================================================

class _SharedPatientCard extends StatelessWidget {
  final String patientId;
  final String fromHospitalId;

  const _SharedPatientCard({
    required this.patientId,
    required this.fromHospitalId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get(),
      builder: (context, patientSnapshot) {
        if (!patientSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }

        if (!patientSnapshot.data!.exists) {
          return const SizedBox();
        }

        final patient =
        patientSnapshot.data!.data() as Map<String, dynamic>;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- PATIENT HEADER --------
                Text(
                  patient['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Age: ${patient['age']} | Blood: ${patient['bloodGroup']}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 6),

                Text(
                  "Patient ID: $patientId",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Divider(height: 24),

                // -------- TREATMENTS --------
                const Text(
                  "Shared Treatment History",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('treatments')
                      .where('patientId', isEqualTo: patientId)
                      .where('hospitalId', isEqualTo: fromHospitalId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final treatments = snapshot.data!.docs;

                    if (treatments.isEmpty) {
                      return const Text(
                        "No treatment records shared",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return Column(
                      children: treatments.map((doc) {
                        final t =
                        doc.data() as Map<String, dynamic>;

                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Diagnosis: ${t['diagnosis']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Treatment: ${t['treatmentPlan']}",
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
