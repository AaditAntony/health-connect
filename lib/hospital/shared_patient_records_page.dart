import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPatientRecordsPage extends StatelessWidget {
  const SharedPatientRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Shared Patient Records"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;

              return _SharedPatientCard(
                patientId: data['patientId'],
                fromHospitalId: data['fromHospitalId'],
                fromHospitalName: data['fromHospitalName'],
                sharedAt: data['createdAt'],
                sealBase64: data['sealSignBase64'],
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
  final String fromHospitalName;
  final Timestamp sharedAt;
  final String sealBase64;

  const _SharedPatientCard({
    required this.patientId,
    required this.fromHospitalId,
    required this.fromHospitalName,
    required this.sharedAt,
    required this.sealBase64,
  });

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

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
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= PATIENT HEADER =================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF7C3AED),
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Age: ${patient['age']} • Blood: ${patient['bloodGroup']}",
                              style:
                              const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Patient ID: $patientId",
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ================= TREATMENTS =================
                const Text(
                  "Shared Treatment History",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

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
                        final t = doc.data() as Map<String, dynamic>;
                        final String? imageBase64 =
                        t['reportImageBase64'];

                        return Container(
                          margin:
                          const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              _sectionTitle("Diagnosis"),
                              Text(t['diagnosis']),
                              const SizedBox(height: 10),

                              _sectionTitle("Treatment Plan"),
                              Text(t['treatmentPlan']),
                              const SizedBox(height: 12),

                              if (imageBase64 != null &&
                                  imageBase64.isNotEmpty)
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  child: Image.memory(
                                    base64Decode(imageBase64),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Divider(),

                // ================= AUTH / AUDIT SECTION =================
                const SizedBox(height: 12),

                Text(
                  "Authorization Details",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                _auditRow("Shared By", fromHospitalName),
                _auditRow("Shared On", _formatDate(sharedAt)),
                _auditRow("Verification", "Authorized Hospital Seal"),

                const SizedBox(height: 16),

                // -------- SEAL (BOTTOM LEFT) --------
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(sealBase64),
                    height: 60,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
        ),
      ),
    );
  }

  Widget _auditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
