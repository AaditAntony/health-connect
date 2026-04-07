import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemStatsTab extends StatelessWidget {
  const SystemStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Performance",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchOverallStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = snapshot.data ?? {};
              
              return Column(
                children: [
                  // --- REVENUE OVERVIEW ---
                  _SummaryBox(
                    title: "Total System Revenue",
                    value: "\u20B9${stats['totalRevenue']}",
                    color: Colors.green,
                    icon: Icons.account_balance_wallet,
                  ),
                  const SizedBox(height: 24),

                  // --- CLINICAL DISTRIBUTION ---
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: "Total Scans",
                          value: stats['scanCount'].toString(),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatMiniCard(
                          title: "Treatments",
                          value: stats['treatmentCount'].toString(),
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- SCAN TYPES BREAKDOWN ---
                  const Text(
                    "Service Utilization",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilizationList(stats['scanTypes'] ?? {}),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationList(Map<String, int> scanTypes) {
    if (scanTypes.isEmpty) return const Text("No data available");
    
    // Sort by count descending
    final sortedKeys = scanTypes.keys.toList()..sort((a, b) => scanTypes[b]!.compareTo(scanTypes[a]!));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedKeys.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final type = sortedKeys[index];
          final count = scanTypes[type];
          return ListTile(
            title: Text(type),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchOverallStats() async {
    double totalRevenue = 0;
    int scanCount = 0;
    int treatmentCount = 0;
    Map<String, int> scanTypes = {};

    final scanSnap = await FirebaseFirestore.instance.collection('scans').get();
    scanCount = scanSnap.docs.length;
    for (var doc in scanSnap.docs) {
      final data = doc.data();
      totalRevenue += (data['cost'] ?? 0.0);
      final type = data['scanType'] ?? "Other";
      scanTypes[type] = (scanTypes[type] ?? 0) + 1;
    }

    final treatSnap = await FirebaseFirestore.instance.collection('treatments').get();
    treatmentCount = treatSnap.docs.length;
    for (var doc in treatSnap.docs) {
      totalRevenue += (doc.data()['cost'] ?? 0.0);
    }

    return {
      'totalRevenue': totalRevenue,
      'scanCount': scanCount,
      'treatmentCount': treatmentCount,
      'scanTypes': scanTypes,
    };
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryBox({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatMiniCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
