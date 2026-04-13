import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_detail_page.dart';

class ApprovedHospitalsTab extends StatelessWidget {
  const ApprovedHospitalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF4F46E5),
            tabs: [
              Tab(text: "Hospitals"),
              Tab(text: "Doctors"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildApprovedList(context, 'hospital'),
                _buildApprovedList(context, 'doctor'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedList(BuildContext context, String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: role)
          .where('approved', isEqualTo: true)
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
          return Center(
            child: Text(
              "No approved ${role}s found.",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;

            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Icon(
                    role == 'hospital' ? Icons.local_hospital : Icons.person,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
                title: Text(
                  role == 'hospital'
                      ? (data['hospitalName'] ?? "Unnamed Hospital")
                      : (data['name'] ?? data['email'] ?? "Unknown Doctor"),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                subtitle: Text(role == 'hospital'
                    ? "District: ${data['district'] ?? '-'}"
                    : "Doctor ID: $id"),
                trailing: const _ApprovedBadge(),
                onTap: role == 'hospital'
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalDetailPage(hospitalId: id),
                          ),
                        );
                      }
                    : null, // Additional doctor info later
              ),
            );
          },
        );
      },
    );
  }
}

class _ApprovedBadge extends StatelessWidget {
  const _ApprovedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Approved",
        style: TextStyle(
          color: Color(0xFF059669),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
