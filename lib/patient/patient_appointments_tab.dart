import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_consultation_page.dart';
import 'book_hospital_test_page.dart';

class PatientAppointmentsTab extends StatelessWidget {
  final String patientId;

  const PatientAppointmentsTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildAppointmentsList(),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        highlightElevation: 0,
        backgroundColor: const Color(0xFF7C3AED),
        onPressed: () => _showBookingOptions(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Book New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showBookingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              const Text(
                "New Booking",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select the type of appointment you need",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _bookingOptionItem(
                context: context,
                icon: Icons.person_rounded,
                title: "Doctor Consultation",
                subtitle: "Specialist health checkup",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookConsultationPage(patientId: patientId)));
                },
              ),
              const SizedBox(height: 12),
              _bookingOptionItem(
                context: context,
                icon: Icons.local_hospital_rounded,
                title: "Hospital Test / Scan",
                subtitle: "Lab tests, X-rays, or MRI",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookHospitalTestPage(patientId: patientId)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bookingOptionItem({required BuildContext context, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Connection failed", style: TextStyle(color: Colors.grey)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                const Text("No appointments scheduled", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'Consultation';
            final status = data['status'] ?? 'pending';

            Color statusColor;
            if (status == 'approved') statusColor = const Color(0xFF10B981);
            else if (status == 'rejected') statusColor = const Color(0xFFEF4444);
            else statusColor = const Color(0xFFF59E0B);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            type == 'Test' ? Icons.biotech_rounded : Icons.medical_services_rounded,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${data['targetName'] ?? 'Unknown Facility'}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    if (data['requestedDoctorName'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            "Dr. ${data['requestedDoctorName']}",
                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            " • ${data['department']}",
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(data['date'] ?? "", style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(data['time'] ?? "", style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                    if (status == 'rejected' && data['hospitalRejectReason'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${data['hospitalRejectReason']}",
                                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
