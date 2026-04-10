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
        backgroundColor: const Color(0xFFF2F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          title: const Text("Medical History", style: TextStyle(fontWeight: FontWeight.bold)),
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
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("No doctor prescriptions found", style: TextStyle(color: Colors.grey)));

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
                        Text("Prescription on $dateStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailBox(title: "Medicines", value: data['medicines'] ?? "-", color: const Color(0xFFF3F0FF), accent: const Color(0xFF7C3AED)),
                    _detailBox(title: "Recommended Activities", value: data['activities'] ?? "-", color: const Color(0xFFECFDF5), accent: const Color(0xFF16A34A)),
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
          .where('patientId', isEqualTo: widget.patientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No medical records found", style: TextStyle(color: Colors.grey)));

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
            if (dtField is Timestamp && (lastVisit == null || dtField.toDate().isAfter(lastVisit!))) {
              lastVisit = dtField.toDate();
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Patient Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                _summaryCard(title: "Patient ID", value: widget.patientId, color: const Color(0xFF0284C7), icon: Icons.badge),
                _summaryCard(title: "Hospitals Visited", value: grouped.length.toString(), color: const Color(0xFF0D9488), icon: Icons.local_hospital),
                _summaryCard(title: "Total Treatments", value: docs.length.toString(), color: const Color(0xFF16A34A), icon: Icons.medical_services),
                if (lastVisit != null)
                  _summaryCard(title: "Last Visit", value: lastVisit!.toLocal().toString().split('.')[0], color: const Color(0xFFD97706), icon: Icons.event),
              ],
            ),
            const SizedBox(height: 28),
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
                  Container(
                    width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: const [Icon(Icons.local_hospital, color: Color(0xFF0284C7)), SizedBox(width: 10), Text("Hospital Record", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                  ),
                  ...records.map((record) {
                    final dynamic dtField = record['timestamp'] ?? record['createdAt'];
                    final date = (dtField is Timestamp) ? dtField.toDate().toLocal().toString().split('.')[0] : "Pending...";
                    return Card(
                      elevation: 1, margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [const Icon(Icons.event_note, color: Color(0xFF0284C7)), const SizedBox(width: 8), Text("Visit Date: $date", style: const TextStyle(fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 16),
                            _detailBox(title: "Diagnosis", value: record['diagnosis'], color: const Color(0xFFF1F5F9), accent: const Color(0xFF0284C7)),
                            _detailBox(title: "Treatment Plan", value: record['treatmentPlan'], color: const Color(0xFFECFDF5), accent: const Color(0xFF16A34A)),
                            if (record['reportImageBase64'] != null)
                              Padding(padding: const EdgeInsets.only(top: 12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(record['reportImageBase64']), height: 200, width: double.infinity, fit: BoxFit.cover))),
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _mergedStream,
      initialData: _latestData,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData && _latestData == null) return const Center(child: CircularProgressIndicator());

        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text("No scan reports found", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index];
            final timestamp = data['timestamp'] as Timestamp?;
            final dateStr = timestamp != null ? timestamp.toDate().toLocal().toString().split('.')[0] : "Pending...";
            final isHospital = data['source'] == 'hospital';

            return Card(
              elevation: 2, margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isHospital ? Icons.local_hospital : Icons.biotech, color: isHospital ? const Color(0xFF0284C7) : const Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(data['scanType'] ?? "Scan Result", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: (isHospital ? Colors.blue : Colors.purple).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(isHospital ? "Hospital" : "Clinic", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHospital ? Colors.blue : Colors.purple)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _detailBox(title: isHospital ? "Result" : "Procedure", value: data['scanInfo'] ?? "-", color: isHospital ? const Color(0xFFF1F5F9) : const Color(0xFFF3F0FF), accent: isHospital ? const Color(0xFF0284C7) : const Color(0xFF7C3AED)),
                    _detailBox(title: "Observations", value: data['observations'] ?? "-", color: const Color(0xFFF8FAFC), accent: const Color(0xFF64748B)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        const Icon(Icons.person, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(data['provider'] ?? "Unknown", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
      width: 170, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 10), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)), const SizedBox(height: 4), Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12))]),
    );
  }

  Widget _detailBox({required String title, required String value, required Color color, required Color accent}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: accent, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: accent)), const SizedBox(height: 6), Text(value)]),
    );
  }
}
