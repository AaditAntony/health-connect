import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_treatement_page.dart';


class HospitalPatientListPage extends StatelessWidget {
  const HospitalPatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔒 Unique hospital ID (from Firebase Auth)
    final String hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Patients"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
        // 🔒 FILTER: show only this hospital’s patients
            .where('hospitalId', isEqualTo: hospitalId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data!.docs;

          if (patients.isEmpty) {
            return const Center(
              child: Text("No patients added yet"),
            );
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final doc = patients[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    data['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Age: ${data['age']} | Blood: ${data['bloodGroup']}",
                  ),
                  trailing: const Icon(Icons.medical_services),

                  // 👉 Click patient → add treatment
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTreatmentPage(
                          patientId: doc.id,      // 🔗 Patient ID
                          hospitalId: hospitalId, // 🔗 Hospital ID
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
