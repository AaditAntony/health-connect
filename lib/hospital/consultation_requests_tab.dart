import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsultationRequestsTab extends StatelessWidget {
  const ConsultationRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Doctor Consultations",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              SizedBox(height: 4),
              Text(
                "Review and approve patient consultation bookings.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('targetId', isEqualTo: hospitalId)
                .where('type', isEqualTo: 'Consultation')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                return const Center(child: Text("No consultation requests found."));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final data = req.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  final patient = data['patientMetadata'] ?? {};

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient['name'] ?? "Unknown Patient",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Age: ${patient['age']} | ${patient['gender']} | ${patient['phone']}",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              _StatusChip(status: status),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.person_search, color: Color(0xFF0891B2), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Requested Doctor: ${data['requestedDoctorName']} (${data['department']})",
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Reason: ${data['reason'] ?? 'Not specified'}",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(data['date'] ?? ""),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(data['time'] ?? ""),
                            ],
                          ),
                          if (status == 'pending') ...[
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _rejectRequest(context, req.id),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text("Reject"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _approveRequest(context, req.id, hospitalId, patient),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0891B2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Approve & Assign"),
                                ),
                              ],
                            ),
                          ],
                          if (status == 'rejected' && data['hospitalRejectReason'] != null) ...[
                             const SizedBox(height: 12),
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                               child: Text("Rejection Reason: ${data['hospitalRejectReason']}", style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
                             )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _approveRequest(BuildContext context, String appId, String hospitalId, Map patient) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Search for existing patient in this hospital
      final query = await FirebaseFirestore.instance
          .collection('patients')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('phone', isEqualTo: patient['phone'])
          .limit(1)
          .get();

      String hospitalPatientId;

      if (query.docs.isNotEmpty) {
        // Use existing record
        hospitalPatientId = query.docs.first.id;
      } else {
        // Create new record for this hospital
        final newPatient = await FirebaseFirestore.instance.collection('patients').add({
          "name": patient['name'],
          "age": patient['age'],
          "gender": patient['gender'],
          "phone": patient['phone'],
          "hospitalId": hospitalId,
          "createdAt": FieldValue.serverTimestamp(),
          "addedVia": "AppBooking"
        });
        hospitalPatientId = newPatient.id;
      }

      // 2. Update appointment
      await FirebaseFirestore.instance.collection('appointments').doc(appId).update({
        'status': 'approved',
        'hospitalPatientId': hospitalPatientId,
      });

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Approved and Patient Linked.")));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _rejectRequest(BuildContext context, String appId) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Appointment"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Reason for rejection (e.g. Doctor Unavailable)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (result == true) {
      await FirebaseFirestore.instance.collection('appointments').doc(appId).update({
        'status': 'rejected',
        'hospitalRejectReason': reasonController.text.trim(),
      });
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
