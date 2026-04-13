import 'package:flutter/material.dart';

class DoctorSchedulePage extends StatelessWidget {
  const DoctorSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Work Schedule",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your default working hours for the current week.",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDaySlot("Monday", "09:00 AM - 05:00 PM", true),
                _buildDaySlot("Tuesday", "09:00 AM - 05:00 PM", true),
                _buildDaySlot("Wednesday", "09:00 AM - 01:00 PM", true),
                _buildDaySlot("Thursday", "09:00 AM - 05:00 PM", true),
                _buildDaySlot("Friday", "09:00 AM - 04:00 PM", true),
                _buildDaySlot("Saturday", "Closed", false),
                _buildDaySlot("Sunday", "Emergency Only", false),
                
                const SizedBox(height: 48),
                
                const Text(
                  "Service Metrics",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
        ),
      ],
    );
  }

  Widget _buildDaySlot(String day, String hours, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isActive ? const Color(0xFF0F172A) : Colors.grey,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF0D9488).withOpacity(0.08) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hours,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF0D9488) : Colors.grey,
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
      ],
    );
  }
}
