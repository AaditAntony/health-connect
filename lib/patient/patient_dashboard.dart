import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_medical_history_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int currentIndex = 0;
  String? patientId;

  @override
  void initState() {
    super.initState();
    _loadPatientId();
  }

  Future<void> _loadPatientId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('patient_users')
        .doc(uid)
        .get();

    setState(() {
      patientId = doc['patientId'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (patientId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      PatientMedicalHistoryPage(patientId: patientId!),
      const _PlaceholderPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers),
            label: "More",
          ),
        ],
      ),
    );
  }
}

// ---------------- PLACEHOLDER PAGE ----------------

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "More features coming soon",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
// ok