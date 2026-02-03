import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_treatement_page.dart';

class PatientRecordsTab extends StatelessWidget {
  final String hospitalId;

  const PatientRecordsTab({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patient Records",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
            // ✅ FILTER ONLY — NO orderBy
                .where('hospitalId', isEqualTo: hospitalId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final patients = snapshot.data!.docs;

              if (patients.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No patients found"),
                );
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: patients.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return _PatientCard(
                    hospitalId: hospitalId,
                    patientId: doc.id,
                    patientData: data,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- PATIENT CARD ----------------

class _PatientCard extends StatelessWidget {
  final String hospitalId;
  final String patientId;
  final Map<String, dynamic> patientData;

  const _PatientCard({
    required this.hospitalId,
    required this.patientId,
    required this.patientData,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- BASIC INFO --------
              Text(
                patientData['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Age: ${patientData['age']} | "
                    "Gender: ${patientData['gender']} | "
                    "Blood: ${patientData['bloodGroup']}",
              ),
              const SizedBox(height: 6),
              Text("Phone: ${patientData['phone']}"),
              if ((patientData['email'] ?? "").toString().isNotEmpty)
                Text("Email: ${patientData['email']}"),

              const Divider(height: 24),

              // -------- LATEST TREATMENT --------
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('treatments')
                    .where('hospitalId', isEqualTo: hospitalId)
                    .where('patientId', isEqualTo: patientId)
                // ✅ NO orderBy HERE
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      "No treatment records yet",
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  final tData =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Latest Diagnosis",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tData['diagnosis'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Treatment Plan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tData['treatmentPlan'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // -------- ACTIONS --------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTreatmentPage(
                            patientId: patientId,
                            hospitalId: hospitalId,
                          ),
                        ),
                      );
                    },
                    child: const Text("Add Treatment"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
