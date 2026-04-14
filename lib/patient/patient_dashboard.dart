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
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HealthConnect",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Your Personal Health Hub",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Recent Receipts",
            icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF7C3AED)),
            onPressed: () => _showRecentReceipts(context),
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Colors.redAccent),
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
          const SizedBox(width: 8),
        ],
      ),

      // ================= BODY =================
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey<int>(currentIndex),
            child: pages[currentIndex],
          ),
        ),
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: "Overview",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined),
              activeIcon: Icon(Icons.history_edu_rounded),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: "Appts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome_rounded),
              label: "Smart-Plan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_rounded),
              label: "Consent",
            ),
          ],
        ),
      ),
    );
  }

  void _showRecentReceipts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED)),
                  SizedBox(width: 12),
                  Text("Billing History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(),
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
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          const Text("No transactions found", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
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
                    padding: const EdgeInsets.all(24),
                    itemCount: sortedDocs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final data = sortedDocs[index];
                      final type = data['type'] ?? "Consultation";
                      final date = data['date'] ?? "Recent";
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              type == 'Test' ? Icons.biotech_rounded : Icons.medical_services_rounded,
                              color: const Color(0xFF7C3AED),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            type == 'Test' ? (data['testType'] ?? "Diagnostic Test") : (data['requestedDoctorName'] ?? "Doctor Consultation"),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          subtitle: Text("${data['targetName']}\n$date", style: const TextStyle(height: 1.5, fontSize: 13)),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.download_rounded, color: Color(0xFF7C3AED), size: 20),
                              onPressed: () => PdfExportUtility.generatePaymentReceipt({
                                ...data,
                                'serviceType': type == 'Test' ? 'Hospital Test' : 'Doctor Consultation',
                                'amount': type == 'Test' ? 1000 : 500,
                              }),
                            ),
                          ),
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
