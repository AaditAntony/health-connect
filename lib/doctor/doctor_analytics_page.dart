import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorAnalyticsPage extends StatelessWidget {
  const DoctorAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not Logged In"));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Performance Analytics",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        const Text(
          "Overview format of your monthly performance.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatCard("Total\nPatients", "128", Icons.people, const Color(0xFF0D9488)),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                
                _buildActivityItem("Consultations", 0.75, const Color(0xFF0D9488)),
                _buildActivityItem("Surgeries", 0.15, Colors.red),
                _buildActivityItem("Follow-ups", 0.40, Colors.green),
                _buildActivityItem("Emergency Cases", 0.10, Colors.orange),
                
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Color(0xFF0D9488)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Efficiency Tip",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
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
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
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
