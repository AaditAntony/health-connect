import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:health_connect/admin/admin_payments_page.dart';
import 'package:health_connect/admin/pending_request_tab.dart';
import 'package:health_connect/web/admin_login_page.dart';

import 'overview_tab.dart';
import 'approved_hospitals_tab.dart';
import 'hospital_analytics_tab.dart';
import 'doctor_analytics_tab.dart';
import 'system_stats_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
    );
  }

  final List<Widget> _pages = const [
    OverviewTab(),
    PendingRequestsTab(),
    ApprovedHospitalsTab(),
    HospitalAnalyticsTab(),
    DoctorAnalyticsTab(),
    SystemStatsTab(),
    AdminPaymentsPage(),
  ];

  final List<String> _titles = [
    "Overview",
    "Pending Requests",
    "Approved Entities",
    "Hospital Analytics",
    "Doctor Analytics",
    "System Performance",
    "Payments",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: const [
          Icon(Icons.shield_outlined, color: Color(0xFF7C3AED)),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin Dashboard",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "System Admin",
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
            decoration: BoxDecoration(
              color: Color(0xFF7C3AED),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  "Admin Panel",
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
          _buildDrawerItem(1, Icons.pending_actions, "Pending Requests"),
          _buildDrawerItem(2, Icons.verified_user, "Approved Entities"),
          const Divider(),
          _buildDrawerItem(3, Icons.analytics, "Hospital Analytics"),
          _buildDrawerItem(4, Icons.people_outline, "Doctor Analytics"),
          _buildDrawerItem(5, Icons.query_stats, "System Performance"),
          const Divider(),
          _buildDrawerItem(6, Icons.payments, "Payments"),
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
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Close drawer
      },
    );
  }
}
