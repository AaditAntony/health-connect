import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum HospitalTab {
  overview,
  patients,
  addPatient,
  requests,
}

class HospitalWebLayout extends StatelessWidget {
  final HospitalTab currentTab;
  final Widget child;
  final String hospitalName;
  final String hospitalId;

  const HospitalWebLayout({
    super.key,
    required this.currentTab,
    required this.child,
    required this.hospitalName,
    required this.hospitalId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.local_hospital, color: Colors.blue),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Hospital ID: $hospitalId",
                  style: const TextStyle(
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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            alignment: Alignment.centerLeft,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _TabButton(
                  label: "Overview",
                  active: currentTab == HospitalTab.overview,
                  onTap: () {},
                ),
                _TabButton(
                  label: "Patient Records",
                  active: currentTab == HospitalTab.patients,
                  onTap: () {},
                ),
                _TabButton(
                  label: "Add Patient",
                  active: currentTab == HospitalTab.addPatient,
                  onTap: () {},
                ),
                _TabButton(
                  label: "Data Requests",
                  active: currentTab == HospitalTab.requests,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),

      // 🌐 WEB CONTENT AREA
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}

// ---------------- TAB BUTTON WIDGET ----------------

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.blue : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            if (active)
              Container(
                height: 3,
                width: 30,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
