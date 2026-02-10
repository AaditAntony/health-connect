import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceivedDataRequestsPage extends StatelessWidget {
  const ReceivedDataRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Data Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('data_requests')
            .where('toHospitalId', isEqualTo: hospitalId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No incoming requests",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              return _RequestCard(
                requestId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const _RequestCard({
    required this.requestId,
    required this.data,
  });

  Future<void> _updateStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance
        .collection('data_requests')
        .doc(requestId)
        .update({
      "status": status,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'accepted'
              ? "Data request accepted"
              : "Data request rejected",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sealBase64 = data['sealSignBase64'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HEADER ----------
            Text(
              "Data Transfer Request",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "From Hospital:",
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              data['fromHospitalName'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Patient ID: ${data['patientId']}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // ---------- ACTIONS ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _updateStatus(context, 'rejected'),
                  child: const Text("Reject"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _updateStatus(context, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),

            // ---------- SEAL (BOTTOM LEFT) ----------
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Authorized by",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        base64Decode(sealBase64),
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
