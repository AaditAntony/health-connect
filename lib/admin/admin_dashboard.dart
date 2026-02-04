import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_connect/admin/overview_tab.dart';
import 'package:health_connect/admin/pending_request_tab.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ---------------- APP BAR ----------------
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

        // ---------------- TAB BAR ----------------
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
                          "3",
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

      // ---------------- BODY ----------------
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: TabBarView(
          controller: _tabController,
          children: [
            //_overviewTab(),
            OverviewTab(),
            PendingRequestsTab(),
            _approvedPlaceholder(),
          ],
        ),
      ),
    );
  }

  // ================= OVERVIEW TAB =================

  // Widget _overviewTab() {
  //   return SingleChildScrollView(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           "System Overview",
  //           style: TextStyle(
  //             fontSize: 22,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //
  //         // -------- STAT CARDS --------
  //         Wrap(
  //           spacing: 16,
  //           runSpacing: 16,
  //           children: [
  //             _statCard(
  //               title: "Total Hospitals",
  //               value: "15",
  //               icon: Icons.local_hospital,
  //               color: Colors.blue,
  //             ),
  //             _statCard(
  //               title: "Total Patients",
  //               value: "3,456",
  //               icon: Icons.people,
  //               color: Colors.green,
  //             ),
  //             _statCard(
  //               title: "Pending Approvals",
  //               value: "3",
  //               icon: Icons.pending_actions,
  //               color: Colors.purple,
  //             ),
  //             _statCard(
  //               title: "Data Share Requests",
  //               value: "28",
  //               icon: Icons.share,
  //               color: Colors.orange,
  //             ),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 32),
  //
  //         // -------- RECENT ACTIVITY --------
  //         Card(
  //           elevation: 2,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Padding(
  //             padding: const EdgeInsets.all(24),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: const [
  //                 Text(
  //                   "Recent Activity",
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 SizedBox(height: 16),
  //
  //                 _ActivityItem(
  //                   color: Colors.green,
  //                   title: "New hospital registration request",
  //                   subtitle: "County Regional Hospital · 2 hours ago",
  //                 ),
  //                 Divider(),
  //
  //                 _ActivityItem(
  //                   color: Colors.blue,
  //                   title: "Hospital approved",
  //                   subtitle: "University Health · 5 hours ago",
  //                 ),
  //                 Divider(),
  //
  //                 _ActivityItem(
  //                   color: Colors.purple,
  //                   title: "Data sharing request processed",
  //                   subtitle:
  //                   "Memorial Hospital → Central Medical · 1 day ago",
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ================= STAT CARD =================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PLACEHOLDERS =================

  // Widget _pendingPlaceholder() {
  //   return const Center(
  //     child: Text(
  //       "Pending Requests UI – Next Task",
  //       style: TextStyle(color: Colors.grey),
  //     ),
  //   );
  // }

  Widget _approvedPlaceholder() {
    return const Center(
      child: Text(
        "Approved Hospitals UI – Next Task",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

// ================= ACTIVITY ITEM =================

class _ActivityItem extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
