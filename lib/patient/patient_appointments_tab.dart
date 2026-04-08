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
      backgroundColor: const Color(0xFFF5F6FA),
      body: _buildAppointmentsList(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        onPressed: () {
          _showBookingOptions(context);
        },
        icon: const Icon(Icons.add),
        label: const Text("Book"),
      ),
    );
  }

  void _showBookingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "What would you like to book?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE9FE),
                    child: Icon(Icons.person, color: Color(0xFF7C3AED)),
                  ),
                  title: const Text("Doctor Consultation"),
                  subtitle: const Text("Book an appointment with a doctor"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookConsultationPage(patientId: patientId),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE9FE),
                    child: Icon(Icons.local_hospital, color: Color(0xFF7C3AED)),
                  ),
                  title: const Text("Hospital Test / Scan"),
                  subtitle: const Text("Book a lab test, X-ray, or MRI"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookHospitalTestPage(patientId: patientId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "You have no upcoming appointments.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'Consultation'; // 'Consultation' or 'Test'
            final status = data['status'] ?? 'pending';

            Color statusColor;
            if (status == 'approved') statusColor = Colors.green;
            else if (status == 'rejected') statusColor = Colors.red;
            else statusColor = Colors.orange;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEDE9FE),
                  child: Icon(
                    type == 'Test' ? Icons.biotech : Icons.medical_services,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                title: Text(
                  "${data['targetName'] ?? 'Unknown Hospital'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (data['requestedDoctorName'] != null)
                      Text(
                        "Dr: ${data['requestedDoctorName']} (${data['department']})",
                        style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(data['date'] ?? ""),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(data['time'] ?? ""),
                      ],
                    ),
                    if (status == 'rejected' && data['hospitalRejectReason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Note: ${data['hospitalRejectReason']}",
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
