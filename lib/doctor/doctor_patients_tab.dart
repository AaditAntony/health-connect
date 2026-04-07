import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                  radius: 28,
                  child: const Icon(Icons.person, color: Color(0xFF7C3AED), size: 32),
                ),
                title: Text(
                  "Patient ID: $pId",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Last Visit: $lastAppt", style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.list_alt, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Total Appointments: $totalAppts", style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
