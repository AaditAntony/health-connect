import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMedicalHistoryPage extends StatelessWidget {
  final String patientId;

  const PatientMedicalHistoryPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          title: const Text(
            "Medical History",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF0F172A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF7C3AED),
            tabs: [
              Tab(text: "Hospital Records"),
              Tab(text: "Doctor Prescriptions"),
              Tab(text: "Scan Reports"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHospitalRecords(),
            _buildDoctorPrescriptions(),
            _buildScanRecords(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPrescriptions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
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
          return const Center(
            child: Text("No doctor prescriptions found", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final dateStr = data['timestamp'] != null 
                ? (data['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                : 'Unknown Date';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_information, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Text(
                          "Prescription on $dateStr",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailBox(
                      title: "Medicines",
                      value: data['medicines'] ?? "-",
                      color: const Color(0xFFF3F0FF),
                      accent: const Color(0xFF7C3AED),
                    ),
                    _detailBox(
                      title: "Recommended Activities",
                      value: data['activities'] ?? "-",
                      color: const Color(0xFFECFDF5),
                      accent: const Color(0xFF16A34A),
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

  Widget _buildHospitalRecords() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
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
          return const Center(
            child: Text(
              "No medical records found",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final Map<String, List<Map<String, dynamic>>> grouped = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          grouped.putIfAbsent(data['hospitalId'], () => []);
          grouped[data['hospitalId']]!.add(data);
        }

        DateTime? lastVisit;
        for (var list in grouped.values) {
          for (var record in list) {
            final dynamic dtField = record['timestamp'] ?? record['createdAt'];
            if (dtField != null && dtField is Timestamp) {
              final date = dtField.toDate();
              if (lastVisit == null || date.isAfter(lastVisit!)) {
                lastVisit = date;
              }
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Patient Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard(
                  title: "Patient ID",
                  value: patientId,
                  color: const Color(0xFF0284C7),
                  icon: Icons.badge,
                ),
                _summaryCard(
                  title: "Hospitals Visited",
                  value: grouped.length.toString(),
                  color: const Color(0xFF0D9488),
                  icon: Icons.local_hospital,
                ),
                _summaryCard(
                  title: "Total Treatments",
                  value: docs.length.toString(),
                  color: const Color(0xFF16A34A),
                  icon: Icons.medical_services,
                ),
                if (lastVisit != null)
                  _summaryCard(
                    title: "Last Visit",
                    value: lastVisit!.toLocal().toString().split('.')[0],
                    color: const Color(0xFFD97706),
                    icon: Icons.event,
                  ),
            ],
            ),
            const SizedBox(height: 28),
            ...grouped.entries.map((entry) {
              final records = entry.value;
              records.sort((a, b) {
                final aDt = a['timestamp'] ?? a['createdAt'];
                final bDt = b['timestamp'] ?? b['createdAt'];
                final t1 = aDt is Timestamp ? aDt.toDate() : DateTime.now();
                final t2 = bDt is Timestamp ? bDt.toDate() : DateTime.now();
                return t2.compareTo(t1);
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.local_hospital, color: Color(0xFF0284C7)),
                        SizedBox(width: 10),
                        Text(
                          "Hospital Record",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  ...records.map((record) {
                    final dynamic dtField = record['timestamp'] ?? record['createdAt'];
                    final date = (dtField != null && dtField is Timestamp) 
                        ? dtField.toDate().toLocal().toString().split('.')[0]
                        : "Pending...";
                    final imageBase64 = record['reportImageBase64'];

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_note, color: Color(0xFF0284C7)),
                                const SizedBox(width: 8),
                                Text(
                                  "Visit Date: $date",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _detailBox(
                              title: "Diagnosis",
                              value: record['diagnosis'],
                              color: const Color(0xFFF1F5F9),
                              accent: const Color(0xFF0284C7),
                            ),
                            _detailBox(
                              title: "Treatment Plan",
                              value: record['treatmentPlan'],
                              color: const Color(0xFFECFDF5),
                              accent: const Color(0xFF16A34A),
                            ),
                            if (imageBase64 != null && imageBase64.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(imageBase64),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildScanRecords() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('scans')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
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
          return const Center(child: Text("No scan reports found", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'];
            final dateStr = (timestamp != null && timestamp is Timestamp)
                ? timestamp.toDate().toLocal().toString().split('.')[0]
                : "Pending...";

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.biotech, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['scanType'] ?? "Diagnostic Scan",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _detailBox(
                      title: "Procedure / Region",
                      value: data['scanInfo'] ?? "-",
                      color: const Color(0xFFF3F0FF),
                      accent: const Color(0xFF7C3AED),
                    ),
                    _detailBox(
                      title: "Observations",
                      value: data['observations'] ?? "-",
                      color: const Color(0xFFF1F5F9),
                      accent: const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Referred by: ${data['doctorName'] ?? "Unknown"}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
  }

  Widget _summaryCard({required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _detailBox({required String title, required String value, required Color color, required Color accent}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}
