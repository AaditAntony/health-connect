import 'package:flutter/material.dart';

class DoctorSchedulePage extends StatelessWidget {
  const DoctorSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("My Work Schedule"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Availability",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your default working hours for the current week.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            _buildDaySlot("Monday", "09:00 AM - 05:00 PM", true),
            _buildDaySlot("Tuesday", "09:00 AM - 05:00 PM", true),
            _buildDaySlot("Wednesday", "09:00 AM - 01:00 PM", true),
            _buildDaySlot("Thursday", "09:00 AM - 05:00 PM", true),
            _buildDaySlot("Friday", "09:00 AM - 04:00 PM", true),
            _buildDaySlot("Saturday", "Closed", false),
            _buildDaySlot("Sunday", "Emergency Only", false),
            
            const SizedBox(height: 48),
            
            // Stats Row
            const Text(
              "Service Metrics",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(24),
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
                children: [
                  _buildMetricRow("Active Appointments", "14"),
                  const Divider(height: 32),
                  _buildMetricRow("Next Open Slot", "Tomorrow, 10 AM"),
                  const Divider(height: 32),
                  _buildMetricRow("Avg Consultation", "20 Min"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySlot(String day, String hours, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.1)),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF7C3AED).withOpacity(0.08) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hours,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF7C3AED) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
