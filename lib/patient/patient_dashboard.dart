import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/patient/patient_auth_page.dart';
import 'package:health_connect/patient/patient_consent_page.dart';
import 'package:health_connect/patient/patient_smartcare_plan_page.dart';
import 'package:health_connect/patient/pdf_export_utility.dart';
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
            tooltip: "Recent Receipts",
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _showRecentReceipts(context),
          ),
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

  void _showRecentReceipts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text("Recent Receipts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('patientId', isEqualTo: patientId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text("No booking records found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("User ID: $patientId", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    );
                  }

                  // In-memory sorting by timestamp
                  final sortedDocs = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    data['id'] = d.id;
                    return data;
                  }).toList();
                  
                  sortedDocs.sort((a, b) {
                    final t1 = a['timestamp'] as Timestamp?;
                    final t2 = b['timestamp'] as Timestamp?;
                    if (t1 == null) return 1;
                    if (t2 == null) return -1;
                    return t2.compareTo(t1);
                  });

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: sortedDocs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = sortedDocs[index];
                      final type = data['type'] ?? "Consultation";
                      final date = data['date'] ?? "Recent";
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEDE9FE),
                          child: Icon(
                            type == 'Test' ? Icons.biotech : Icons.medical_services,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        title: Text(
                          type == 'Test' ? (data['testType'] ?? "Diagnostic Test") : (data['requestedDoctorName'] ?? "Doctor Consultation"),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("${data['targetName']} • $date"),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, color: Color(0xFF7C3AED)),
                          onPressed: () => PdfExportUtility.generatePaymentReceipt({
                            ...data,
                            'serviceType': type == 'Test' ? 'Hospital Test' : 'Doctor Consultation',
                            'amount': type == 'Test' ? 1000 : 500, // Fallback amounts if not in record
                          }),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
