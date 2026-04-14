import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMedicalHistoryPage extends StatefulWidget {
  final String patientId;

  const PatientMedicalHistoryPage({super.key, required this.patientId});

  @override
  State<PatientMedicalHistoryPage> createState() => _PatientMedicalHistoryPageState();
}

class _PatientMedicalHistoryPageState extends State<PatientMedicalHistoryPage> {
  Stream<List<Map<String, dynamic>>>? _mergedStream;
  StreamSubscription? _sub1;
  StreamSubscription? _sub2;
  final _controller = StreamController<List<Map<String, dynamic>>>.broadcast();
  List<Map<String, dynamic>>? _latestData;

  @override
  void initState() {
    super.initState();
    _setupMergedStream();
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    _controller.close();
    super.dispose();
  }

  void _setupMergedStream() {
    QuerySnapshot? scansSnap;
    QuerySnapshot? treatmentsSnap;

    void combine() {
      List<Map<String, dynamic>> all = [];
      
      // Add doctor scans
      if (scansSnap != null) {
        for (var doc in scansSnap!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          all.add({
            ...data,
            'source': 'doctor',
            'provider': data['doctorName'] ?? "Clinic",
          });
        }
      }

      // Add hospital tests
      if (treatmentsSnap != null) {
        for (var doc in treatmentsSnap!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final diag = (data['diagnosis'] ?? "").toString();
          if (diag.contains("Result:")) {
            final parts = diag.split("Result:");
            all.add({
              'scanType': parts[0].trim(),
              'scanInfo': data['treatmentPlan'] ?? "-",
              'observations': parts.length > 1 ? parts[1].trim() : diag,
              'provider': "Hospital Record",
              'timestamp': data['createdAt'] ?? data['timestamp'],
              'source': 'hospital',
            });
          }
        }
      }

      // Sort in-memory (Avoiding Firestore composite index requirement)
      all.sort((a, b) {
        final t1 = a['timestamp'] as Timestamp?;
        final t2 = b['timestamp'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      if (mounted) {
        setState(() {
          _latestData = all;
        });
      }
      if (!_controller.isClosed) _controller.add(all);
    }

    debugPrint("MergedStream: Initializing scans listener for ${widget.patientId}");
    _sub1 = FirebaseFirestore.instance
        .collection('scans')
        .where('patientId', isEqualTo: widget.patientId)
        .snapshots()
        .listen(
          (s) {
            debugPrint("MergedStream: Received ${s.docs.length} scans");
            scansSnap = s; 
            combine(); 
          },
          onError: (e) {
            debugPrint("MergedStream Error (scans): $e");
            if (!_controller.isClosed) _controller.addError(e);
          }
        );

    debugPrint("MergedStream: Initializing treatments listener for ${widget.patientId}");
    _sub2 = FirebaseFirestore.instance
        .collection('treatments')
        .where('patientId', isEqualTo: widget.patientId)
        .snapshots()
        .listen(
          (t) {
            debugPrint("MergedStream: Received ${t.docs.length} treatments");
            treatmentsSnap = t; 
            combine(); 
          },
          onError: (e) {
            debugPrint("MergedStream Error (treatments): $e");
            if (!_controller.isClosed) _controller.addError(e);
          }
        );

    _mergedStream = _controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          title: const Text("Medical Records", style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF7C3AED),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: "Hospital"),
              Tab(text: "Prescriptions"),
              Tab(text: "Scans"),
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
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Connection error"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                const Text("No prescriptions found", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final dateStr = data['timestamp'] != null 
                ? (data['timestamp'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                : 'Unknown Date';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.medical_information_rounded, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Digital Prescription", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailBox(title: "Medications", value: data['medicines'] ?? "-", accent: const Color(0xFF7C3AED)),
                  const SizedBox(height: 12),
                  _detailBox(title: "Recommended Activities", value: data['activities'] ?? "-", accent: const Color(0xFF10B981)),
                ],
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
          .where('patientId', isEqualTo: widget.patientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Connection error"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                const Text("No hospital records", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          grouped.putIfAbsent(data['hospitalId'], () => []);
          grouped[data['hospitalId']]!.add(data);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text("AT A GLANCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _summaryCard(title: "Hospitals", value: grouped.length.toString(), icon: Icons.local_hospital_rounded, color: const Color(0xFF3B82F6)),
                _summaryCard(title: "Treatments", value: docs.length.toString(), icon: Icons.medical_services_rounded, color: const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 32),
            const Text("CHRONOLOGICAL LOG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            ...grouped.entries.map((entry) {
              final records = entry.value;
              records.sort((a, b) {
                final t1 = (a['timestamp'] ?? a['createdAt']) as Timestamp?;
                final t2 = (b['timestamp'] ?? b['createdAt']) as Timestamp?;
                return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...records.map((record) {
                    final dynamic dtField = record['timestamp'] ?? record['createdAt'];
                    final date = (dtField is Timestamp) ? dtField.toDate().toLocal().toString().split('.')[0] : "Pending...";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_note_rounded, color: Color(0xFF64748B), size: 18),
                              const SizedBox(width: 8),
                              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const Spacer(),
                              const Text("Hospital Record", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _detailBox(title: "Diagnosis", value: record['diagnosis'], accent: const Color(0xFF3B82F6)),
                          const SizedBox(height: 12),
                          _detailBox(title: "Treatment Plan", value: record['treatmentPlan'], accent: const Color(0xFF10B981)),
                          if (record['reportImageBase64'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(base64Decode(record['reportImageBase64']), height: 200, width: double.infinity, fit: BoxFit.cover),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildScanRecords() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _mergedStream,
      initialData: _latestData,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Connection error"));
        if (!snapshot.hasData && _latestData == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.biotech_outlined, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                const Text("No scan reports found", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = items[index];
            final timestamp = data['timestamp'] as Timestamp?;
            final dateStr = timestamp != null ? timestamp.toDate().toLocal().toString().split('.')[0] : "Pending...";
            final isHospital = data['source'] == 'hospital';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isHospital ? const Color(0xFF3B82F6) : const Color(0xFF7C3AED)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isHospital ? Icons.local_hospital_rounded : Icons.biotech_rounded,
                          color: isHospital ? const Color(0xFF3B82F6) : const Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['scanType'] ?? "Clinical Result", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailBox(
                    title: isHospital ? "Result Description" : "Procedure Details",
                    value: data['scanInfo'] ?? "-",
                    accent: isHospital ? const Color(0xFF3B82F6) : const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 12),
                  _detailBox(title: "Medical Observations", value: data['observations'] ?? "-", accent: const Color(0xFF64748B)),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        "Provider: ${data['provider'] ?? 'Clinical Facility'}",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryCard({required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: color)),
        ],
      ),
    );
  }

  Widget _detailBox({required String title, required String value, required Color accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}
