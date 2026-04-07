import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= TOP SUMMARY =================
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: LinearProgressIndicator(),
              );
            }

            final payments = snapshot.data!.docs;

            double totalRevenue = 0;
            for (var doc in payments) {
              final data = doc.data() as Map<String, dynamic>;
              totalRevenue += (data['amount'] ?? 0);
            }

            final totalTransactions = payments.length;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _statCard(
                    title: "Total Revenue",
                    value: "₹ ${totalRevenue.toInt()}",
                    color: Colors.green,
                    icon: Icons.currency_rupee,
                  ),
                  const SizedBox(width: 16),
                  _statCard(
                    title: "Transactions",
                    value: totalTransactions.toString(),
                    color: Colors.blue,
                    icon: Icons.receipt_long,
                  ),
                ],
              ),
            );
          },
        ),

        // ================= PAYMENT LIST =================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = snapshot.data!.docs;

              if (payments.isEmpty) {
                return const Center(
                  child: Text(
                    "No payments found",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final data = payments[index].data() as Map<String, dynamic>;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // ICON
                          Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE9FE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments,
                              color: Color(0xFF7C3AED),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹ ${data['amount']}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Patient: ${data['patientId']}"),
                                Text("Hospital: ${data['hospitalId']}"),
                                Text("Plan: ${data['planId']}"),
                              ],
                            ),
                          ),

                          // STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['status'],
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

  // ================= STAT CARD =================

  Widget _statCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
