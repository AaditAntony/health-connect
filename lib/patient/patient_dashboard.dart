import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/patient/patient_auth_page.dart';
import 'package:health_connect/patient/patient_consent_page.dart';
import 'package:health_connect/patient/patient_smartcare_plan_page.dart';
import 'patient_medical_history_page.dart';
import 'patient_appointments_tab.dart'; 
import 'patient_overview_tab.dart'; // newly added

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

    if (mounted) {
      setState(() {
        patientId = doc['patientId'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (patientId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      PatientOverviewTab(patientId: patientId!),
      PatientMedicalHistoryPage(patientId: patientId!),
      PatientAppointmentsTab(patientId: patientId!),
      PatientSmartCarePlanPage(),
      PatientConsentPage(patientId: patientId!)
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Patient Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientAuthPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),

      // ================= BODY =================
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[currentIndex],
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Overview",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: "Appts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers_outlined),
            activeIcon: Icon(Icons.layers),
            label: "Smart-Plan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security_outlined),
            activeIcon: Icon(Icons.security),
            label: "Consent",
          ),
        ],
      ),
    );
  }
}
