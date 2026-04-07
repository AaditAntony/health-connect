import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_detail_page.dart';

class PendingRequestsTab extends StatelessWidget {
  const PendingRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF7C3AED),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF7C3AED),
            tabs: [
              Tab(text: "Hospitals"),
              Tab(text: "Doctors"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingList(context, 'hospital'),
                _buildPendingList(context, 'doctor'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList(BuildContext context, String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: role)
          .where('approved', isEqualTo: false)
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

        // Note: For hospitals, we normally also checked profileSubmitted == true.
        // Let's filter that locally to keep the query simple.
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (role == 'hospital' || role == 'doctor') {
            return data['profileSubmitted'] == true;
          }
          return true; // Other roles pending immediately
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              "No pending ${role}s requests",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            final id = filteredDocs[index].id;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEDE9FE),
                  child: Icon(
                    role == 'hospital' ? Icons.local_hospital : Icons.person,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                title: Text(
                  role == 'hospital'
                      ? (data['hospitalName'] ?? "Unnamed Hospital")
                      : (data['doctorName'] ?? data['email'] ?? "Unknown Doctor"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(role == 'hospital'
                    ? (data['district'] ?? "No District")
                    : "Doctor Applicant"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approve(context, id, role),
                      tooltip: "Approve",
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _reject(context, id, role),
                      tooltip: "Reject",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approve(BuildContext context, String id, String role) async {
    await FirebaseFirestore.instance
        .collection('accounts')
        .doc(id)
        .update({"approved": true});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${role.toUpperCase()} Approved")),
    );
  }

  Future<void> _reject(BuildContext context, String id, String role) async {
    await FirebaseFirestore.instance.collection('accounts').doc(id).delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${role.toUpperCase()} Rejected")),
    );
  }
}
