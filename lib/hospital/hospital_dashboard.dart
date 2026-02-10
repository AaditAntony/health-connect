import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_connect/hospital/patient_records_tab_wrapper.dart';
import 'package:health_connect/hospital/shared_patient_records_page.dart';
import 'add_patient_page.dart';
import 'hospital_overview_tab.dart';
import 'data_requests_tab.dart';

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 24,
        title: Row(
          children: const [
            Icon(Icons.local_hospital, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hospital Dashboard",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Hospital Panel",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.black),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // ================= TAB BAR =================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF7C3AED),
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Patient Records"),
                Tab(text: "Add Patient"),
                Tab(text: "Data Requests"),
                Tab(text: "Shared Records"),
              ],
            ),
          ),
        ),
      ),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: TabBarView(
          controller: _tabController,
          children: const [
            HospitalOverviewTab(),
            PatientRecordsTabWrapper(),
            AddPatientPage(),
            DataRequestsTab(),
            SharedPatientRecordsPage()
          ],
        ),
      ),
    );
  }
}
