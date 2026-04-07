import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorAnalyticsPage extends StatelessWidget {
  const DoctorAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Not Logged In")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Performance Analytics"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overview Statistics",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              children: [
                _buildStatCard("Total\nPatients", "128", Icons.people, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard("Monthly\nAppointments", "42", Icons.calendar_month, Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard("Average\nRating", "4.8", Icons.star, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard("Completed\nTreatments", "96", Icons.check_circle, Colors.green),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text(
              "Activity Breakdown",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Mock Chart or List
            _buildActivityItem("Consultations", 0.75, Colors.blue),
            _buildActivityItem("Surgeries", 0.15, Colors.red),
            _buildActivityItem("Follow-ups", 0.40, Colors.green),
            _buildActivityItem("Emergency Cases", 0.10, Colors.orange),
            
            const SizedBox(height: 40),
            
            // Tips Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Efficiency Tip",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Your peak activity is between 10 AM and 2 PM. Consider scheduling breaks after 3 PM.",
                          style: TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("${(percentage * 100).toInt()}%", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
