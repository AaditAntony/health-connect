import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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

                  // --- REVENUE SPLIT PIE ---
                  _RevenueSplitPie(
                    scanRevenue: stats['scanRevenue'] ?? 0.0,
                    treatRevenue: stats['treatRevenue'] ?? 0.0,
                  ),
                  const SizedBox(height: 32),

                  // --- SCAN TYPES BREAKDOWN ---
                  const Text(
                    "Service Utilization (Scan Popularity)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _UtilizationBarChart(scanTypes: stats['scanTypes'] ?? {}),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  Future<Map<String, dynamic>> _fetchOverallStats() async {
    double scanRevenue = 0;
    double treatRevenue = 0;
    int scanCount = 0;
    int treatmentCount = 0;
    Map<String, int> scanTypes = {};

    final scanSnap = await FirebaseFirestore.instance.collection('scans').get();
    scanCount = scanSnap.docs.length;
    for (var doc in scanSnap.docs) {
      final data = doc.data();
      scanRevenue += (data['cost'] ?? 0.0);
      final type = data['scanType'] ?? "Other";
      scanTypes[type] = (scanTypes[type] ?? 0) + 1;
    }

    final treatSnap = await FirebaseFirestore.instance.collection('treatments').get();
    treatmentCount = treatSnap.docs.length;
    for (var doc in treatSnap.docs) {
      treatRevenue += (doc.data()['cost'] ?? 0.0);
    }

    return {
      'totalRevenue': scanRevenue + treatRevenue,
      'scanRevenue': scanRevenue,
      'treatRevenue': treatRevenue,
      'scanCount': scanCount,
      'treatmentCount': treatmentCount,
      'scanTypes': scanTypes,
    };
  }
}

class _UtilizationBarChart extends StatelessWidget {
  final Map<String, int> scanTypes;
  const _UtilizationBarChart({required this.scanTypes});

  @override
  Widget build(BuildContext context) {
    if (scanTypes.isEmpty) return const Text("No scan data available");
    
    final sortedKeys = scanTypes.keys.toList()..sort((a, b) => scanTypes[b]!.compareTo(scanTypes[a]!));
    final displayKeys = sortedKeys.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < displayKeys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            displayKeys[value.toInt()],
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const Text("");
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(displayKeys.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: scanTypes[displayKeys[i]]!.toDouble(),
                      color: const Color(0xFF7C3AED),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueSplitPie extends StatelessWidget {
  final double scanRevenue;
  final double treatRevenue;
  const _RevenueSplitPie({required this.scanRevenue, required this.treatRevenue});

  @override
  Widget build(BuildContext context) {
    final total = scanRevenue + treatRevenue;
    if (total == 0) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Revenue Composition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow(Colors.blue, "Scans", "\u20B9${scanRevenue.toStringAsFixed(0)}"),
                      const SizedBox(height: 12),
                      _legendRow(Colors.orange, "Treatments", "\u20B9${treatRevenue.toStringAsFixed(0)}"),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(color: Colors.blue, value: scanRevenue, radius: 40, showTitle: false),
                        PieChartSectionData(color: Colors.orange, value: treatRevenue, radius: 40, showTitle: false),
                      ],
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(value, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
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
