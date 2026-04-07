import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HospitalPatientsPage extends StatefulWidget {
  const HospitalPatientsPage({super.key});

  @override
  State<HospitalPatientsPage> createState() => _HospitalPatientsPageState();
}

class _HospitalPatientsPageState extends State<HospitalPatientsPage> {
  String? hospitalId;

  @override
  void initState() {
    super.initState();
    _fetchDoctorHospital();
  }

  Future<void> _fetchDoctorHospital() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('accounts').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        hospitalId = doc.data()?['hospitalId'];
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hospitalId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Hospital Directory"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // In a real app, patients would be linked to hospitals.
        // For now, let's assume patients register at a hospital or we fetch from a 'hospital_patients' collection.
        // Or we can fetch all 'patient_users' if they have a 'lastHospitalId' field.
        // Let's assume there is a 'hospital_patients' subcollection or similar.
        // Actually, the user said "doctor can view the patient connected to the hospital".
        // Let's query 'patient_users' where 'hospitalId' matches.
        stream: FirebaseFirestore.instance
            .collection('patient_users')
            .where('hospitalId', isEqualTo: hospitalId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No patients found in this hospital."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? "Unknown Patient";
              final pId = docs[index].id;
              final phone = data['phone'] ?? "N/A";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                          child: const Icon(Icons.person, color: Color(0xFF7C3AED)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Patient ID: $pId"),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _copyToClipboard(pId, "Patient ID"),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text("Copy ID"),
                          ),
                          TextButton.icon(
                            onPressed: () => _copyToClipboard(phone, "Phone Number"),
                            icon: const Icon(Icons.phone_android, size: 18),
                            label: const Text("Copy Phone"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
