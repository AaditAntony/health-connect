import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../patient/patient_medical_history_page.dart';
import 'add_treatment_page.dart';
import 'add_scan_page.dart';

class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      // Listen to appointments assigned to this doctor
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('requestedDoctorId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \\n${snapshot.error}", textAlign: TextAlign.center));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No patients found."));
        }

        final docs = snapshot.data!.docs;

        // In-memory sorting by timestamp descending
        final sortedDocs = docs.toList();
        sortedDocs.sort((a, b) {
          final t1 = a['timestamp'] as Timestamp?;
          final t2 = b['timestamp'] as Timestamp?;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        // Deduplicate patients using their patientId
        // Also keep track of the most recent appointment date for that patient.
        final Map<String, Map<String, dynamic>> uniquePatientsMap = {};

        for (var doc in sortedDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final patientId = data['patientId'] as String?;
          final date = data['date'] ?? 'Unknown Date';
          
          if (patientId == null || patientId.isEmpty) continue;

          // Process only the first occurrence (since it's ordered by timestamp descending)
          if (!uniquePatientsMap.containsKey(patientId)) {
             uniquePatientsMap[patientId] = {
               'patientId': patientId,
               'lastAppointment': date,
               'totalAppointments': 1,
             };
          } else {
             // Increment count if already exists
             uniquePatientsMap[patientId]!['totalAppointments'] += 1;
          }
        }

        if (uniquePatientsMap.isEmpty) {
          return const Center(child: Text("No linked patients found."));
        }

        final patientsList = uniquePatientsMap.values.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patientsList.length,
          itemBuilder: (context, index) {
            final patientData = patientsList[index];
            final pId = patientData['patientId'];
            final lastAppt = patientData['lastAppointment'];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('patients').doc(pId).get(),
              builder: (context, patientSnapshot) {
                final patientInfo = patientSnapshot.data?.data() as Map<String, dynamic>?;
                final name = patientInfo?['name'] ?? "Patient: $pId";
                final phone = patientInfo?['phone'] ?? "N/A";

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                      radius: 24,
                      child: const Icon(Icons.person, color: Color(0xFF7C3AED), size: 28),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ID: $pId", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text("Last Visit: $lastAppt", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () => _copyToClipboard(pId, "Patient ID"),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text("Copy ID", style: TextStyle(fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () => _copyToClipboard(phone, "Phone Number"),
                              icon: const Icon(Icons.phone_android, size: 16),
                              label: const Text("Copy Phone", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTreatmentPage(patientId: pId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.medical_services_outlined, size: 18),
                                label: const Text("Treatment"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF7C3AED),
                                  side: const BorderSide(color: Color(0xFF7C3AED)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddScanPage(patientId: pId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.biotech_outlined, size: 18),
                                label: const Text("Add Scan"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF7C3AED),
                                  side: const BorderSide(color: Color(0xFF7C3AED)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientMedicalHistoryPage(patientId: pId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text("View Full Medical History"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
