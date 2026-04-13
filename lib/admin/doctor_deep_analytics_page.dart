import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorDeepAnalyticsPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String department;

  const DoctorDeepAnalyticsPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.department,
  });

  @override
  State<DoctorDeepAnalyticsPage> createState() => _DoctorDeepAnalyticsPageState();
}

class _DoctorDeepAnalyticsPageState extends State<DoctorDeepAnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDoctorDetailedData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!;
          final patientRevenue = data['patientRevenue'] as Map<String, double>;
          final activityMix = data['activityMix'] as Map<String, int>;
          final totalRevenue = data['totalRevenue'] as double;
          final totalRecords = data['totalRecords'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumDoctorHeader(totalRevenue, totalRecords),
                const SizedBox(height: 28),
                
                _buildSectionLabel("PATIENT REVENUE PORTFOLIO", "Highest revenue contributions from specific patient accounts."),
                const SizedBox(height: 16),
                _HorizontalPatientBarChart(patientRevenue: patientRevenue),
                
                const SizedBox(height: 28),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ClinicalDonutCard(
                        title: "ACTIVITY MIX",
                        subtitle: "Consultations vs Scans.",
                        activityMix: activityMix,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryIndicatorCard(
                        title: "EFFICIENCY SCORE",
                        subtitle: "Clinical volume throughput.",
                        value: "94%",
                        trend: "+2.1%",
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                _buildSectionLabel("VALUE PER CONSULTATION TREND", "Historical analysis of clinical value generated per transaction over time."),
                const SizedBox(height: 16),
                _ValueDensityAreaChart(allRecords: data['allRecords'] as List<Map<String, dynamic>>),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String text, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPremiumDoctorHeader(double revenue, int records) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.department.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(widget.doctorName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 28,
                child: Icon(Icons.medical_services, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _headerStatItem("TOTAL REVENUE", "\u20B9${revenue.toStringAsFixed(0)}"),
              const SizedBox(width: 48),
              _headerStatItem("HNDL RECORDS", records.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Future<Map<String, dynamic>> _fetchDoctorDetailedData() async {
    double totalRevenue = 0;
    Map<String, double> patientRevenue = {};
    Map<String, int> activityMix = {'Scans': 0, 'Treatments': 0};
    List<Map<String, dynamic>> allRecords = [];

    final scanSnap = await FirebaseFirestore.instance.collection('scans')
        .where('doctorId', isEqualTo: widget.doctorId).get();
    for (var doc in scanSnap.docs) {
      final d = doc.data();
      final cost = (d['cost'] ?? 0.0);
      final timestamp = d['timestamp'] ?? d['createdAt'];
      if (timestamp != null) {
        totalRevenue += cost;
        patientRevenue[d['patientId'] ?? 'Unkn'] = (patientRevenue[d['patientId']] ?? 0) + cost;
        activityMix['Scans'] = (activityMix['Scans'] ?? 0) + 1;
        allRecords.add({'timestamp': timestamp, 'cost': cost});
      }
    }

    final treatSnap = await FirebaseFirestore.instance.collection('treatments')
        .where('doctorId', isEqualTo: widget.doctorId).get();
    for (var doc in treatSnap.docs) {
      final d = doc.data();
      final cost = (d['cost'] ?? 0.0);
      final timestamp = d['timestamp'] ?? d['createdAt'];
      if (timestamp != null) {
        totalRevenue += cost;
        patientRevenue[d['patientId'] ?? 'Unkn'] = (patientRevenue[d['patientId']] ?? 0) + cost;
        activityMix['Treatments'] = (activityMix['Treatments'] ?? 0) + 1;
        allRecords.add({'timestamp': timestamp, 'cost': cost});
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'patientRevenue': patientRevenue,
      'activityMix': activityMix,
      'totalRecords': scanSnap.docs.length + treatSnap.docs.length,
      'allRecords': allRecords,
    };
  }
}

class _HorizontalPatientBarChart extends StatelessWidget {
  final Map<String, double> patientRevenue;
  const _HorizontalPatientBarChart({required this.patientRevenue});

  @override
  Widget build(BuildContext context) {
    final sorted = patientRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final display = sorted.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          ...List.generate(display.length, (i) {
            final item = display[i];
            final percent = item.value / (sorted.first.value == 0 ? 1 : sorted.first.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Patient: ${item.key.substring(0, 8)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Text("\u20B9${item.value.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _legendItem(Colors.blue.shade400, "Relative Revenue Impact Per Patient"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ClinicalDonutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, int> activityMix;
  const _ClinicalDonutCard({required this.title, required this.subtitle, required this.activityMix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(color: const Color(0xFF6366F1), value: activityMix['Scans']!.toDouble(), radius: 12, showTitle: false),
                  PieChartSectionData(color: const Color(0xFF10B981), value: activityMix['Treatments']!.toDouble(), radius: 12, showTitle: false),
                ],
                centerSpaceRadius: 25,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _donutLegend(const Color(0xFF6366F1), "Scans: ${activityMix['Scans']}"),
          const SizedBox(height: 4),
          _donutLegend(const Color(0xFF10B981), "Treatments: ${activityMix['Treatments']}"),
        ],
      ),
    );
  }

  Widget _donutLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _SummaryIndicatorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String trend;
  final Color color;
  const _SummaryIndicatorCard({required this.title, required this.subtitle, required this.value, required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_upward, size: 12, color: color),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueDensityAreaChart extends StatelessWidget {
  final List<Map<String, dynamic>> allRecords;
  const _ValueDensityAreaChart({required this.allRecords});

  @override
  Widget build(BuildContext context) {
    final sorted = allRecords..sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp']));
    final lastN = sorted.length > 10 ? sorted.sublist(sorted.length - 10) : sorted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade50, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text("\u20B9${(v/1000).toStringAsFixed(0)}k", style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(lastN.length, (i) => FlSpot(i.toDouble(), (lastN[i]['cost'] as double))),
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF6366F1).withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                    dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: const Color(0xFF6366F1))),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF0F172A),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "Consultation Value: \u20B9${spot.y.toStringAsFixed(0)}",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _chartLegend(const Color(0xFF6366F1), "Clinical Value Distribution Over Time"),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
