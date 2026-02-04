import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMedicalHistoryPage extends StatelessWidget {
  final String patientId;

  const PatientMedicalHistoryPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Medical History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('treatments')
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No medical records found"));
          }

          // ---------------- GROUP BY HOSPITAL ----------------
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            grouped.putIfAbsent(data['hospitalId'], () => []);
            grouped[data['hospitalId']]!.add(data);
          }

          // ---------------- CALCULATE SUMMARY ----------------
          DateTime? lastVisit;
          for (var list in grouped.values) {
            for (var record in list) {
              final date = (record['createdAt'] as Timestamp).toDate();
              if (lastVisit == null || date.isAfter(lastVisit!)) {
                lastVisit = date;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ================= PATIENT SUMMARY =================
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Patient Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow("Patient ID", patientId),
                      _infoRow(
                        "Hospitals Visited",
                        grouped.keys.length.toString(),
                      ),
                      _infoRow(
                        "Total Treatments",
                        docs.length.toString(),
                      ),
                      if (lastVisit != null)
                        _infoRow(
                          "Last Visit",
                          lastVisit!.toLocal().toString().split('.')[0],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ================= HOSPITAL RECORDS =================
              ...grouped.entries.map((entry) {
                final hospitalId = entry.key;
                final records = entry.value;

                records.sort((a, b) {
                  final t1 = (a['createdAt'] as Timestamp).toDate();
                  final t2 = (b['createdAt'] as Timestamp).toDate();
                  return t2.compareTo(t1);
                });

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hospital ID: $hospitalId",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Visits: ${records.length} | "
                              "Last Visit: ${(records.first['createdAt'] as Timestamp).toDate().toLocal().toString().split('.')[0]}",
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const Divider(height: 24),

                        ...records.map((record) {
                          final date =
                          (record['createdAt'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split('.')[0];

                          final String? imageBase64 =
                          record['reportImageBase64'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle("Visit on $date"),
                              _sectionText(
                                  "Diagnosis", record['diagnosis']),
                              _sectionText(
                                  "Treatment Plan",
                                  record['treatmentPlan']),
                              if (imageBase64 != null &&
                                  imageBase64.isNotEmpty)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 8),
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(imageBase64),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const Divider(height: 32),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _sectionText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
