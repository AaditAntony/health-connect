import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_detail_page.dart';

class PendingRequestsTab extends StatelessWidget {
  const PendingRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= COUNT HEADER =================
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('accounts')
              .where('role', isEqualTo: 'hospital')
              .where('approved', isEqualTo: false)
              .where('profileSubmitted', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final count = snapshot.data!.docs.length;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    "Pending Requests: $count",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // ================= LIST =================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('accounts')
                .where('role', isEqualTo: 'hospital')
                .where('approved', isEqualTo: false)
                .where('profileSubmitted', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No pending hospital requests",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  return _PendingHospitalCard(
                    hospitalId: docs[index].id,
                    data: data,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================= CARD =================

class _PendingHospitalCard extends StatelessWidget {
  final String hospitalId;
  final Map<String, dynamic> data;

  const _PendingHospitalCard({required this.hospitalId, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HospitalDetailPage(hospitalId: hospitalId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- ICON --------
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF7C3AED),
                ),
              ),

              const SizedBox(width: 16),

              // -------- DETAILS --------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['hospitalName'] ?? "Unnamed Hospital",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['district'] ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['email'] ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Established: ${data['establishedYear'] ?? '-'}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // -------- ACTIONS --------
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('accounts')
                          .doc(hospitalId)
                          .update({"approved": true});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hospital Approved")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(90, 36),
                    ),
                    child: const Text("Approve"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('accounts')
                          .doc(hospitalId)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hospital Rejected")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(90, 36),
                    ),
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
