import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_detail_page.dart';

class ApprovedHospitalsTab extends StatelessWidget {
  const ApprovedHospitalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'hospital')
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No approved hospitals",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 250,
            headingRowColor: MaterialStateProperty.all(
              const Color(0xFFF3F0FF),
            ),
            columns: const [
              DataColumn(label: Text("Hospital Name")),
              DataColumn(label: Text("District")),
              DataColumn(label: Text("Established")),
              DataColumn(label: Text("Status")),
            ],
            rows: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return DataRow(
                cells: [
                  DataCell(
                    Text(data['hospitalName'] ?? "-"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HospitalDetailPage(hospitalId: doc.id),
                        ),
                      );
                    },
                  ),
                  DataCell(Text(data['district'] ?? "-")),
                  DataCell(Text(data['establishedYear'] ?? "-")),
                  const DataCell(
                    _ApprovedBadge(),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ---------------- STATUS BADGE ----------------

class _ApprovedBadge extends StatelessWidget {
  const _ApprovedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Approved",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
