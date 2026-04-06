import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upload_test_result_page.dart';

class TestAppointmentsTab extends StatelessWidget {
  const TestAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('targetId', isEqualTo: currentUserId)
            .where('type', isEqualTo: 'Test')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No incoming test appointments."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final appId = docs[index].id;
              final status = data['status'] ?? 'pending';

              Color statusColor = Colors.orange;
              if (status == 'approved') statusColor = Colors.green;
              if (status == 'rejected') statusColor = Colors.red;
              if (status == 'completed') statusColor = Colors.blue;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Patient ID: ${data['patientId']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Requested Test: ${data['testType'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['date'] ?? ""),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['time'] ?? ""),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (status == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateStatus(appId, 'rejected'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text("Reject"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _updateStatus(appId, 'approved'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Approve"),
                            ),
                          ],
                        ),
                      if (status == 'approved')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UploadTestResultPage(
                                    appointmentId: appId,
                                    patientId: data['patientId'],
                                    hospitalId: currentUserId,
                                    testType: data['testType'] ?? 'Lab Test',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.upload_file, color: Colors.white),
                            label: const Text("Upload Test Results", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).update({
      'status': newStatus,
    });
  }
}
