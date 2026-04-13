import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_connect/hospital/add_patient_page.dart';
import 'package:health_connect/hospital/consultation_requests_tab.dart';
import 'package:health_connect/hospital/patient_records_tab_wrapper.dart';
import 'package:health_connect/hospital/shared_patient_records_page.dart';
import 'package:health_connect/hospital/smart_care_plan_page.dart';
import 'package:health_connect/web/hospital_login_page.dart';
import 'package:health_connect/hospital/data_requests_tab.dart';
import 'package:health_connect/hospital/transfer_requests_tab.dart';
import 'hospital_overview_tab.dart';
import 'registration_requests_tab.dart';
import 'test_appointments_tab.dart';
import 'hospital_fees_page.dart';
import 'hospital_doctors_tab.dart';
import 'hospital_profile_tab.dart';

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  int _selectedIndex = 0;

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HospitalLoginPage()),
    );
  }

  final List<Widget> _pages = [
    const HospitalOverviewTab(),
    const HospitalDoctorsTab(hospitalId: ""),
    const ConsultationRequestsTab(),
    const RegistrationRequestsTab(),
    const AddPatientPage(),
    const PatientRecordsTabWrapper(),
    const TestAppointmentsTab(),
    const SharedPatientRecordsPage(),
    const DataRequestsTab(),
    const TransferRequestsTab(),
    const SmartCarePlanPage(),
    const HospitalFeesPage(),
    const HospitalProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Dynamically update the pages that need hospitalId
    final List<Widget> displayPages = [
      const HospitalOverviewTab(),
      HospitalDoctorsTab(hospitalId: hospitalId),
      const ConsultationRequestsTab(),
      const RegistrationRequestsTab(),
      const AddPatientPage(),
      const PatientRecordsTabWrapper(),
      const TestAppointmentsTab(),
      const SharedPatientRecordsPage(),
      const DataRequestsTab(),
      const TransferRequestsTab(),
      const SmartCarePlanPage(),
      const HospitalFeesPage(),
      const HospitalProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: displayPages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.local_hospital, color: Color(0xFF0891B2), size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hospital Dashboard",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Command Center",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Color(0xFFE11D48)),
            onPressed: logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            width: double.infinity,
            color: const Color(0xFF0891B2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.local_hospital, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  "Hospital Panel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Web Interface",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSidebarItem(0, Icons.dashboard, "Overview"),
                _buildSidebarItem(1, Icons.medical_services, "Doctors List"),
                _buildSidebarItem(
                  2,
                  Icons.assignment_turned_in,
                  "Consultation Requests",
                ),
                _buildSidebarItem(3, Icons.how_to_reg, "Registration Requests"),
                _buildSidebarItem(4, Icons.person_add, "Add Patient"),
                _buildSidebarItem(5, Icons.folder_shared, "Patient Records"),
                _buildSidebarItem(6, Icons.biotech, "Test Appointments"),
                _buildSidebarItem(7, Icons.share, "Shared Records"),
                _buildSidebarItem(8, Icons.compare_arrows, "Request Transfer"),
                _buildSidebarItem(9, Icons.move_to_inbox, "Incoming Transfers"),
                _buildSidebarItem(10, Icons.lightbulb, "Smart Care Plan"),
                _buildSidebarItem(11, Icons.payments, "Manage Fees"),
                _buildSidebarItem(
                  12,
                  Icons.settings_applications,
                  "Hospital Profile",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0891B2).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0891B2).withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0891B2)
                  : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
