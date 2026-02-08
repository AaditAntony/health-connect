import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMedicalHistoryPage extends StatelessWidget {
  final String patientId;

  const PatientMedicalHistoryPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          "Medical History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
            return const Center(
              child: Text(
                "No medical records found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // -------- GROUP BY HOSPITAL --------
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            grouped.putIfAbsent(data['hospitalId'], () => []);
            grouped[data['hospitalId']]!.add(data);
          }

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
              const Text(
                "Patient Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _summaryCard(
                    title: "Patient ID",
                    value: patientId,
                    color: const Color(0xFF0284C7), // blue
                    icon: Icons.badge,
                  ),
                  _summaryCard(
                    title: "Hospitals Visited",
                    value: grouped.length.toString(),
                    color: const Color(0xFF0D9488), // teal
                    icon: Icons.local_hospital,
                  ),
                  _summaryCard(
                    title: "Total Treatments",
                    value: docs.length.toString(),
                    color: const Color(0xFF16A34A), // green
                    icon: Icons.medical_services,
                  ),
                  if (lastVisit != null)
                    _summaryCard(
                      title: "Last Visit",
                      value: lastVisit!
                          .toLocal()
                          .toString()
                          .split('.')[0],
                      color: const Color(0xFFD97706), // amber
                      icon: Icons.event,
                    ),
                ],
              ),

              const SizedBox(height: 28),

              // ================= HOSPITAL SECTIONS =================
              ...grouped.entries.map((entry) {
                final hospitalId = entry.key;
                final records = entry.value;

                records.sort((a, b) {
                  final t1 =
                  (a['createdAt'] as Timestamp).toDate();
                  final t2 =
                  (b['createdAt'] as Timestamp).toDate();
                  return t2.compareTo(t1);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------- HOSPITAL HEADER --------
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.local_hospital,
                            color: Color(0xFF0284C7),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Hospital Record",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -------- VISIT CARDS --------
                    ...records.map((record) {
                      final date =
                      (record['createdAt'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString()
                          .split('.')[0];

                      final imageBase64 =
                      record['reportImageBase64'];

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              // -------- VISIT HEADER --------
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_note,
                                    color: Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Visit Date: $date",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              _detailBox(
                                title: "Diagnosis",
                                value: record['diagnosis'],
                                color: const Color(0xFFF1F5F9),
                                accent: const Color(0xFF0284C7),
                              ),

                              _detailBox(
                                title: "Treatment Plan",
                                value: record['treatmentPlan'],
                                color: const Color(0xFFECFDF5),
                                accent: const Color(0xFF16A34A),
                              ),

                              if (imageBase64 != null &&
                                  imageBase64.isNotEmpty)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 12),
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(imageBase64),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox({
    required String title,
    required String value,
    required Color color,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}
