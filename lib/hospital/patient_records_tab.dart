import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/hospital/patient_ai_summary_page.dart';
import '../patient/patient_medical_history_page.dart';
import 'add_treatement_page.dart';

class PatientRecordsTab extends StatelessWidget {
  final String hospitalId;

  const PatientRecordsTab({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Patient Records",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),

        // -------- PATIENT LIST --------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
                .where('hospitalId', isEqualTo: hospitalId)
                .snapshots(),
            builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final patients = snapshot.data!.docs;

              if (patients.isEmpty) {
                return const Center(
                  child: Text(
                    "No patients added yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: patients.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _PatientCard(
                      hospitalId: hospitalId,
                      patientId: doc.id, // 🔑 Patient ID
                      patientData: data,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================= PATIENT CARD =================

class _PatientCard extends StatelessWidget {
  final String hospitalId;
  final String patientId;
  final Map<String, dynamic> patientData;

  const _PatientCard({
    required this.hospitalId,
    required this.patientId,
    required this.patientData,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- HEADER --------
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFFAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0891B2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      patientData['name'] ?? "Unnamed Patient",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // -------- BASIC INFO --------
              Text(
                "Age: ${patientData['age']} | "
                    "Gender: ${patientData['gender']} | "
                    "Blood: ${patientData['bloodGroup']}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                "Phone: ${patientData['phone']}",
                style: const TextStyle(color: Colors.grey),
              ),
              if ((patientData['email'] ?? "").toString().isNotEmpty)
                Text(
                  "Email: ${patientData['email']}",
                  style: const TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 12),

              // ======== PATIENT ID (ADDED – UI ONLY) ========
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCFFAFE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0891B2).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge,
                      size: 16,
                      color: Color(0xFF0891B2),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Patient ID: $patientId",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0891B2),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF0891B2)),
                      onPressed: () => _copyToClipboard(context, patientId, "Patient ID"),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    patientData['phone'] ?? "N/A",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _copyToClipboard(context, patientData['phone'] ?? "", "Phone"),
                    child: const Text("Copy Phone", style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              // ======== END PATIENT ID ========

              const SizedBox(height: 16),
              const Divider(),

              // -------- LATEST TREATMENT --------
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('treatments')
                    .where('hospitalId', isEqualTo: hospitalId)
                    .where('patientId', isEqualTo: patientId)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
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
                      const SizedBox(height: 10),
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

              // -------- ACTION --------
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Add Treatment",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>AiMedicalSummaryPage(patientId: patientId, hospitalId: hospitalId)
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "AI-Generation",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientMedicalHistoryPage(patientId: patientId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, color: Colors.white),
                  label: const Text(
                    "Full Medical History",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// done p0Hq3hNhwH5vnMI49agc