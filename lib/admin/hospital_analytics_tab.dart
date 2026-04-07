import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalAnalyticsTab extends StatelessWidget {
  const HospitalAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'hospital')
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final hospitals = snapshot.data!.docs;

        if (hospitals.isEmpty) {
          return const Center(child: Text("No approved hospitals found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hospitals.length,
          itemBuilder: (context, index) {
            final hospitalData = hospitals[index].data() as Map<String, dynamic>;
            final hospitalId = hospitals[index].id;
            final hospitalName = hospitalData['hospitalName'] ?? "Unnamed Hospital";

            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchHospitalMetrics(hospitalId),
              builder: (context, metricSnapshot) {
                final metrics = metricSnapshot.data ?? {'revenue': 0.0, 'scans': 0, 'treatments': 0};
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hospitalName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "\u20B9${metrics['revenue']}",
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MetricItem(
                              label: "Total Scans",
                              value: metrics['scans'].toString(),
                              icon: Icons.biotech,
                            ),
                            _MetricItem(
                              label: "Treatments",
                              value: metrics['treatments'].toString(),
                              icon: Icons.medical_services,
                            ),
                            _MetricItem(
                              label: "Avg. Ticket",
                              value: metrics['treatments'] + metrics['scans'] > 0 
                                ? "\u20B9${(metrics['revenue'] / (metrics['treatments'] + metrics['scans'])).toStringAsFixed(0)}" 
                                : "\u20B90",
                              icon: Icons.analytics,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text("Service Mix", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: metrics['treatments'] + metrics['scans'] > 0 
                              ? metrics['treatments'] / (metrics['treatments'] + metrics['scans']) 
                              : 0.5,
                            backgroundColor: Colors.blue.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("Imaging / Scans", style: TextStyle(fontSize: 10, color: Colors.blue)),
                            Text("Treatments", style: TextStyle(fontSize: 10, color: Colors.orange)),
                          ],
                        ),
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

  Future<Map<String, dynamic>> _fetchHospitalMetrics(String hospitalId) async {
    double totalRevenue = 0;
    int totalScans = 0;
    int totalTreatments = 0;

    // Fetch Scans
    final scanSnap = await FirebaseFirestore.instance
        .collection('scans')
        .where('hospitalId', isEqualTo: hospitalId)
        .get();
    totalScans = scanSnap.docs.length;
    for (var doc in scanSnap.docs) {
      totalRevenue += (doc.data()['cost'] ?? 0.0);
    }

    // Fetch Treatments
    final treatSnap = await FirebaseFirestore.instance
        .collection('treatments')
        .where('hospitalId', isEqualTo: hospitalId)
        .get();
    totalTreatments = treatSnap.docs.length;
    for (var doc in treatSnap.docs) {
      totalRevenue += (doc.data()['cost'] ?? 0.0);
    }

    return {
      'revenue': totalRevenue,
      'scans': totalScans,
      'treatments': totalTreatments,
    };
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
