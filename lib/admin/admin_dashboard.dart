import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_connect/admin/pending_request_tab.dart';

import 'overview_tab.dart';
import 'approved_hospitals_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthWrapper will automatically redirect
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
                  ),
                ),
                Text(
                  "System Admin",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
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
              tabs: [
                const Tab(text: "Overview"),
                Tab(
                  child: Row(
                    children: [
                      const Text("Pending Requests"),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "3", // later bind from Firebase
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(text: "Approved Hospitals"),
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
            OverviewTab(),
            PendingRequestsTab(),
            ApprovedHospitalsTab(),
          ],
        ),
      ),
    );
  }
}
