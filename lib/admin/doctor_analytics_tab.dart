import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAnalyticsTab extends StatelessWidget {
  const DoctorAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'doctor')
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final doctors = snapshot.data!.docs;

        if (doctors.isEmpty) {
          return const Center(child: Text("No approved doctors found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctorData = doctors[index].data() as Map<String, dynamic>;
            final doctorId = doctors[index].id;
            final doctorName = doctorData['doctorName'] ?? "Unnamed Doctor";
            final department = doctorData['department'] ?? "General";

            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchDoctorMetrics(doctorId),
              builder: (context, metricSnapshot) {
                final metrics = metricSnapshot.data ?? {'revenue': 0.0, 'clinicalCount': 0};
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$department | ${metrics['clinicalCount']} Records"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\u20B9${metrics['revenue']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const Text("Revenue", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchDoctorMetrics(String doctorId) async {
    double totalRevenue = 0;
    int clinicalCount = 0;

    // Fetch Scans
    final scanSnap = await FirebaseFirestore.instance
        .collection('scans')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    clinicalCount += scanSnap.docs.length;
    for (var doc in scanSnap.docs) {
      totalRevenue += (doc.data()['cost'] ?? 0.0);
    }

    // Fetch Treatments
    final treatSnap = await FirebaseFirestore.instance
        .collection('treatments')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    clinicalCount += treatSnap.docs.length;
    for (var doc in treatSnap.docs) {
      totalRevenue += (doc.data()['cost'] ?? 0.0);
    }

    return {
      'revenue': totalRevenue,
      'clinicalCount': clinicalCount,
    };
  }
}
