import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverviewTab extends StatelessWidget {
  final String hospitalId;

  const OverviewTab({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------- SUMMARY CARDS ----------------
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: "Total Patients",
                stream: FirebaseFirestore.instance
                    .collection('patients')
                    .where('hospitalId', isEqualTo: hospitalId)
                    .snapshots(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: "Medical Records",
                stream: FirebaseFirestore.instance
                    .collection('treatments')
                    .where('hospitalId', isEqualTo: hospitalId)
                    .snapshots(),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: _StaticSummaryCard(
                title: "Pending Requests",
                value: "0",
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ---------------- RECENT PATIENTS ----------------
        const Text(
          "Recent Patients",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('patients')
              .where('hospitalId', isEqualTo: hospitalId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              );
            }

            final patients = snapshot.data!.docs;

            if (patients.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Text("No patients added yet"),
              );
            }

            return Column(
              children: patients.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      data['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Age: ${data['age']} | Blood: ${data['bloodGroup']}",
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ---------------- SUMMARY CARD WITH STREAM ----------------

class _SummaryCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot> stream;

  const _SummaryCard({
    required this.title,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- STATIC SUMMARY CARD ----------------

class _StaticSummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _StaticSummaryCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
