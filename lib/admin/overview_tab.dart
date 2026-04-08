import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Overview",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // ================= STAT CARDS =================
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _TotalHospitalsCard(),
              _TotalPatientsCard(),
              _PendingApprovalsCard(),
              _ApprovedHospitalsCard(),
            ],
          ),

          const SizedBox(height: 32),

          // ================= ANALYTICS GRAPHS =================
          const Text(
            "System Performance Analytics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _RevenueTrendChart(),
          const SizedBox(height: 16),
          _SystemDistributionPie(),

          const SizedBox(height: 32),

          // ================= RECENT ACTIVITY (STATIC) =================
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  _ActivityItem(
                    color: Colors.green,
                    title: "New hospital registration request",
                    subtitle: "2 hours ago",
                  ),
                  Divider(),

                  _ActivityItem(
                    color: Colors.blue,
                    title: "Hospital approved",
                    subtitle: "5 hours ago",
                  ),
                  Divider(),

                  _ActivityItem(
                    color: Colors.purple,
                    title: "Patient record updated",
                    subtitle: "1 day ago",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= STAT CARDS =================

class _TotalHospitalsCard extends StatelessWidget {
  const _TotalHospitalsCard();

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: "Total Hospitals",
      icon: Icons.local_hospital,
      color: Colors.blue,
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'hospital')
          .snapshots(),
    );
  }
}

class _ApprovedHospitalsCard extends StatelessWidget {
  const _ApprovedHospitalsCard();

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: "Approved Hospitals",
      icon: Icons.verified,
      color: Colors.green,
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'hospital')
          .where('approved', isEqualTo: true)
          .snapshots(),
    );
  }
}

class _PendingApprovalsCard extends StatelessWidget {
  const _PendingApprovalsCard();

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: "Pending Approvals",
      icon: Icons.pending_actions,
      color: Colors.orange,
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'hospital')
          .where('approved', isEqualTo: false)
          .where('profileSubmitted', isEqualTo: true)
          .snapshots(),
    );
  }
}

class _TotalPatientsCard extends StatelessWidget {
  const _TotalPatientsCard();

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: "Total Patients",
      icon: Icons.people,
      color: Colors.purple,
      stream: FirebaseFirestore.instance.collection('patients').snapshots(),
    );
  }
}

// ================= GENERIC STAT CARD =================

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
            final count =
            snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================= ACTIVITY ITEM =================

class _ActivityItem extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// ================= ANALYTICS WIDGETS =================

class _RevenueTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: _fetchRevenueTrend(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("7-Day Revenue Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                              return Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!,
                          isCurved: true,
                          color: const Color(0xFF7C3AED),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF7C3AED).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<FlSpot>> _fetchRevenueTrend() async {
    final Map<int, double> dailyRevenue = {};
    for (int i = 0; i < 7; i++) dailyRevenue[i] = 0.0;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Scans
    final scanSnap = await FirebaseFirestore.instance
        .collection('scans')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();
    
    for (var doc in scanSnap.docs) {
      final timestamp = doc.data()['timestamp'] ?? doc.data()['createdAt'];
      if (timestamp != null && timestamp is Timestamp) {
        final date = timestamp.toDate();
        final dayIndex = 6 - now.difference(date).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyRevenue[dayIndex] = (dailyRevenue[dayIndex] ?? 0) + (doc.data()['cost'] ?? 0.0);
        }
      }
    }

    // Treatments
    final treatSnap = await FirebaseFirestore.instance
        .collection('treatments')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    for (var doc in treatSnap.docs) {
      final timestamp = doc.data()['timestamp'] ?? doc.data()['createdAt'];
      if (timestamp != null && timestamp is Timestamp) {
        final date = timestamp.toDate();
        final dayIndex = 6 - now.difference(date).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyRevenue[dayIndex] = (dailyRevenue[dayIndex] ?? 0) + (doc.data()['cost'] ?? 0.0);
        }
      }
    }

    return List.generate(7, (i) => FlSpot(i.toDouble(), dailyRevenue[i]!));
  }
}

class _SystemDistributionPie extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PieChartSectionData>>(
      future: _fetchDistribution(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("User Distribution", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _legendItem(Colors.blue, "Hospitals"),
                      _legendItem(Colors.green, "Doctors"),
                      _legendItem(Colors.purple, "Patients"),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: snapshot.data!,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<List<PieChartSectionData>> _fetchDistribution() async {
    final hospCount = (await FirebaseFirestore.instance.collection('accounts').where('role', isEqualTo: 'hospital').get()).docs.length;
    final docCount = (await FirebaseFirestore.instance.collection('accounts').where('role', isEqualTo: 'doctor').get()).docs.length;
    final patCount = (await FirebaseFirestore.instance.collection('patients').get()).docs.length;

    final total = (hospCount + docCount + patCount).toDouble();
    if (total == 0) return [];

    return [
      PieChartSectionData(color: Colors.blue, value: hospCount.toDouble(), radius: 50, showTitle: false),
      PieChartSectionData(color: Colors.green, value: docCount.toDouble(), radius: 50, showTitle: false),
      PieChartSectionData(color: Colors.purple, value: patCount.toDouble(), radius: 50, showTitle: false),
    ];
  }
}
// the admin done