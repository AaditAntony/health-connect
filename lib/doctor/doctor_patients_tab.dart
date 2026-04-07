import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_treatment_page.dart';
import 'add_scan_page.dart';

class DoctorPatientsTab extends StatelessWidget {
  const DoctorPatientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      // Listen to appointments assigned to this doctor
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('targetId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
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

        // Deduplicate patients using their patientId
        // Also keep track of the most recent appointment date for that patient.
        final Map<String, Map<String, dynamic>> uniquePatientsMap = {};

        for (var doc in docs) {
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
            final totalAppts = patientData['totalAppointments'];

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
                  "Patient ID: $pId",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text("Last Visit: $lastAppt", style: const TextStyle(fontSize: 12)),
                children: [
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
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
