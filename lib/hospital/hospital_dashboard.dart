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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HospitalLoginPage()));
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: displayPages[_selectedIndex],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 0,
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
                  fontSize: 18,
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
        IconButton(
          tooltip: "Logout",
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF7C3AED)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.local_hospital, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  "Hospital Panel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(0, Icons.dashboard, "Overview"),
          _buildDrawerItem(1, Icons.medical_services, "Doctors List"),
          _buildDrawerItem(2, Icons.assignment_turned_in, "Consultation Requests"),
          _buildDrawerItem(3, Icons.how_to_reg, "Registration Requests"),
          _buildDrawerItem(4, Icons.person_add, "Add Patient"),
          _buildDrawerItem(5, Icons.folder_shared, "Patient Records"),
          _buildDrawerItem(6, Icons.biotech, "Test Appointments"),
          _buildDrawerItem(7, Icons.share, "Shared Records"),
          _buildDrawerItem(8, Icons.compare_arrows, "Request Transfer"),
          _buildDrawerItem(9, Icons.move_to_inbox, "Incoming Transfers"),
          _buildDrawerItem(10, Icons.lightbulb, "Smart Care Plan"),
          _buildDrawerItem(11, Icons.payments, "Manage Fees"),
          _buildDrawerItem(12, Icons.settings_applications, "Hospital Profile"),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF7C3AED) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF7C3AED).withOpacity(0.1),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Close drawer
      },
    );
  }
}