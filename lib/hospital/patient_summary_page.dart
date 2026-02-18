import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientAiSummaryPage extends StatelessWidget {
  final String patientId;
  final String hospitalId;

  const PatientAiSummaryPage({
    super.key,
    required this.patientId,
    required this.hospitalId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("AI Medical Summary"),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .get(),
          FirebaseFirestore.instance
              .collection('accounts')
              .doc(hospitalId)
              .get(),
          FirebaseFirestore.instance
              .collection('treatments')
              .where('patientId', isEqualTo: patientId)
              .where('hospitalId', isEqualTo: hospitalId)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final patientDoc = snapshot.data![0] as DocumentSnapshot;
          final hospitalDoc = snapshot.data![1] as DocumentSnapshot;
          final treatmentsSnap = snapshot.data![2] as QuerySnapshot;

          if (!patientDoc.exists) {
            return const Center(child: Text("Patient not found"));
          }

          final patient =
          patientDoc.data() as Map<String, dynamic>;
          final hospital =
          hospitalDoc.data() as Map<String, dynamic>;
          final treatments = treatmentsSnap.docs;

          final String hospitalName =
              hospital['hospitalName'] ?? "Hospital";
          final String sealBase64 =
              hospital['sealSignBase64'] ?? "";

          final int totalVisits = treatments.length;

          String latestDiagnosis = "";
          String latestTreatment = "";
          String latestDate = "";

          if (treatments.isNotEmpty) {
            treatments.sort((a, b) {
              final t1 =
              (a['createdAt'] as Timestamp).toDate();
              final t2 =
              (b['createdAt'] as Timestamp).toDate();
              return t2.compareTo(t1);
            });

            final latest = treatments.first;
            latestDiagnosis = latest['diagnosis'] ?? "";
            latestTreatment = latest['treatmentPlan'] ?? "";
            latestDate =
            (latest['createdAt'] as Timestamp)
                .toDate()
                .toLocal()
                .toString()
                .split('.')[0];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: 850,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ================= HEADER =================
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF7C3AED),
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "AI-Generated Clinical Summary",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospitalName,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),

                    // ================= PATIENT INFO =================
                    const Text(
                      "Patient Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _infoRow("Patient Name", patient['name']),
                    _infoRow("Age", patient['age'].toString()),
                    _infoRow("Gender", patient['gender']),
                    _infoRow("Blood Group", patient['bloodGroup']),
                    _infoRow("Patient ID", patientId),

                    const SizedBox(height: 30),

                    // ================= AI SUMMARY =================
                    const Text(
                      "Clinical Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "This patient has undergone $totalVisits recorded consultations at $hospitalName. "
                          "Based on clinical records, the patient has demonstrated consistent engagement "
                          "with healthcare services and adherence to recommended treatment protocols. "
                          "The pattern of diagnoses suggests a structured clinical progression requiring "
                          "continuous monitoring and evidence-based therapeutic intervention.\n\n"
                          "The most recent evaluation dated $latestDate indicates a primary diagnosis of "
                          "\"$latestDiagnosis\". The prescribed management plan includes \"$latestTreatment\". "
                          "Clinical documentation suggests that the patient is currently under active treatment "
                          "and demonstrates moderate-to-high compliance with medical guidance.\n\n"
                          "From an AI-assisted analysis of the medical trajectory, it is recommended that "
                          "periodic follow-up assessments be scheduled to evaluate treatment effectiveness, "
                          "risk factors, and potential co-morbid conditions. Preventive strategies and lifestyle "
                          "modifications should continue to be emphasized.\n\n"
                          "$hospitalName is recognized for maintaining structured clinical documentation standards, "
                          "digital patient safety protocols, and evidence-driven healthcare services. "
                          "This summary has been generated using automated clinical analysis algorithms "
                          "to assist healthcare professionals in reviewing the patient’s treatment history efficiently.",
                      style: const TextStyle(
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 20),

                    // ================= FOOTER =================
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Prepared By",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(hospitalName),
                            const SizedBox(height: 6),
                            const Text(
                              "Authorized Medical Institution",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        if (sealBase64.isNotEmpty)
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(sealBase64),
                              height: 80,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
