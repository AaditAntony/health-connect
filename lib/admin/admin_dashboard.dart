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
      backgroundColor: const Color(0xFFF8FAFC),
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
          Icon(Icons.shield_outlined, color: Color(0xFF4F46E5)),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Command Center",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "System Admin",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: "Logout",
          icon: const Icon(Icons.logout, color: Color(0xFF0F172A)),
          onPressed: logout,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: const Color(0xFFE2E8F0),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B4B),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/admin_logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Command Center",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Health Connect Admin",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(0, Icons.dashboard_rounded, "Overview"),
                _buildDrawerItem(1, Icons.pending_actions_rounded, "Pending Requests"),
                _buildDrawerItem(2, Icons.verified_user_rounded, "Approved Entities"),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: Color(0xFFE2E8F0)),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text("ANALYTICS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                _buildDrawerItem(3, Icons.analytics_rounded, "Hospital Analytics"),
                _buildDrawerItem(4, Icons.people_outline_rounded, "Doctor Analytics"),
                _buildDrawerItem(5, Icons.query_stats_rounded, "System Performance"),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: Color(0xFFE2E8F0)),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text("MANAGEMENT", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                _buildDrawerItem(6, Icons.account_balance_wallet_rounded, "Payments"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFFEEF2FF),
        tileColor: Colors.transparent,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Close drawer
        },
      ),
    );
  }
}
