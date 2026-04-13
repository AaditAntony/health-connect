import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../web/web_login_choice_page.dart';

import 'upcoming_appointments_tab.dart';
import 'doctor_patients_tab.dart';
import 'treatment_history_tab.dart';
import 'scan_hub_tab.dart';
import 'doctor_schedule_page.dart';
import 'doctor_analytics_page.dart';
import 'doctor_profile_tab.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WebLoginChoicePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    child: _buildBody(),
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text(
            "Doctor Command Center",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
            child: const Icon(Icons.medical_services, color: Color(0xFF0D9488)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isExpanded ? 260 : 80,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, color: Color(0xFF0D9488), size: 32),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
                const Text(
                  "HealthConnect",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _navItem(Icons.calendar_today, "Appointments", 0),
                _navItem(Icons.people_outline, "My Patients", 1),
                _navItem(Icons.history_edu, "Treatment History", 2),
                _navItem(Icons.biotech, "Scan Hub", 3),
                _navItem(Icons.schedule, "Work Schedule", 4),
                _navItem(Icons.analytics_outlined, "Analytics", 5),
                _navItem(Icons.person_outline, "Profile", 6),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          _sidebarAction(Icons.logout, "Logout", logout, Colors.redAccent),
          IconButton(
            icon: Icon(_isExpanded ? Icons.chevron_left : Icons.chevron_right, color: Colors.white54),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 22),
            if (_isExpanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sidebarAction(IconData icon, String title, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Row(
          mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            if (_isExpanded) ...[
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: iconColor, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const UpcomingAppointmentsTab();
      case 1:
        return const DoctorPatientsTab();
      case 2:
        return const TreatmentHistoryTab();
      case 3:
        return const ScanHubTab();
      case 4:
        return const DoctorSchedulePage();
      case 5:
        return const DoctorAnalyticsPage();
      case 6:
        return const DoctorProfileTab();
      default:
        return const UpcomingAppointmentsTab();
    }
  }
}
