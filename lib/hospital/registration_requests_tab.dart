import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationRequestsTab extends StatelessWidget {
  const RegistrationRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patient_registration_requests')
          .where('hospitalId', isEqualTo: hospitalUid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_disabled, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No pending registration requests", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, String requestId, Map<String, dynamic> data) {
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
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFCFFAFE),
                  child: Text(
                    data['name']?[0]?.toUpperCase() ?? "?",
                    style: const TextStyle(color: Color(0xFF0891B2), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${data['age']} yrs • ${data['gender']} • ${data['bloodGroup']}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                _statusBadge("NEW"),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(data['phone'] ?? "No Phone"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleRejection(context, requestId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApproval(context, requestId, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Approve & Register"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFCFFAFE), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Color(0xFF0891B2), fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _handleApproval(BuildContext context, String requestId, Map<String, dynamic> data) async {
    final hospitalUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. Create actual patient record
      final newPatientRef = await FirebaseFirestore.instance.collection('patients').add({
        "name": data['name'],
        "age": data['age'],
        "gender": data['gender'],
        "bloodGroup": data['bloodGroup'],
        "phone": data['phone'],
        "email": data['email'] ?? "",
        "hospitalId": hospitalUid,
        "createdAt": Timestamp.now(),
        "selfRegistered": true, // Mark as self-registered online
      });

      // 2. Link the patient's User account to this new clinical record
      await FirebaseFirestore.instance.collection('patient_users').doc(data['authUid']).set({
        "authUid": data['authUid'],
        "patientId": newPatientRef.id,
        "linkedAt": Timestamp.now(),
      });

      // 3. Complete the request
      await FirebaseFirestore.instance.collection('patient_registration_requests').doc(requestId).delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Patient approved and registered successfully!")));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _handleRejection(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('patient_registration_requests').doc(requestId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration request rejected.")));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
