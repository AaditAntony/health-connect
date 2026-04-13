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
                    color: const Color(0xFF059669),
                    icon: Icons.currency_rupee,
                  ),
                  const SizedBox(width: 16),
                  _statCard(
                    title: "Transactions",
                    value: totalTransactions.toString(),
                    color: const Color(0xFF2563EB),
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
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                              color: Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments,
                              color: Color(0xFF4F46E5),
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
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Patient: ${data['patientId']}", style: const TextStyle(color: Color(0xFF64748B))),
                                Text("Hospital: ${data['hospitalId']}", style: const TextStyle(color: Color(0xFF64748B))),
                                Text("Plan: ${data['planId']}", style: const TextStyle(color: Color(0xFF64748B))),
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
                              color: const Color(0xFF059669).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['status'],
                              style: const TextStyle(
                                color: Color(0xFF059669),
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
          borderRadius: BorderRadius.circular(16),
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
            Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
