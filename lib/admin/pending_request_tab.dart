import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hospital_detail_page.dart';
import 'doctor_detail_page.dart';

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

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (role == 'hospital' || role == 'doctor') {
            return data['profileSubmitted'] == true;
          }
          return true;
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
              elevation: 4,
              shadowColor: Colors.black12,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                onTap: () {
                  // Navigate to the correct detail page based on role
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => role == 'hospital'
                          ? HospitalDetailPage(hospitalId: id)
                          : DoctorDetailPage(doctorId: id),
                    ),
                  );
                },
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role == 'hospital' ? Icons.local_hospital : Icons.person,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                title: Text(
                  role == 'hospital'
                      ? (data['hospitalName'] ?? "Unnamed Hospital")
                      : (data['doctorName'] ?? data['email'] ?? "Unknown Doctor"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(role == 'hospital'
                        ? (data['district'] ?? "No District")
                        : "Specialization: ${data['department'] ?? 'N/A'}"),
                    const SizedBox(height: 4),
                    const Text(
                      "Click to view details and verify",
                      style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
