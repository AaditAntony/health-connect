import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/patient/pdf_export_utility.dart';
import 'package:intl/intl.dart';

class PatientOverviewTab extends StatelessWidget {
  final String patientId;

  const PatientOverviewTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= WELCOME HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Health Insights",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Monitoring your latest clinical vitals and trends.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportPdf(context),
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      "Full Report",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ================= VITALS CHART =================
          _buildVitalsCard(context),

          const SizedBox(height: 32),

          // ================= KEY METRICS =================
          const Text(
            "CORE CLINICAL METRICS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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
                children: const [
                  Text(
                    "Heart Rate Patterns",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "Beats Per Minute (BPM) tracking",
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              _buildLivePulse(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vitals')
                  .where('patientId', isEqualTo: patientId)
                  .where('type', isEqualTo: 'heart_rate')
                  .orderBy('timestamp', descending: true)
                  .limit(7)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Chart Error: Please create composite index in Firestore",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.reversed.toList();

                // Fallback for demo/student project completeness if no data exists
                if (docs.isEmpty) {
                  return _buildEmptyVitalsChart();
                }

                try {
                  final spots = List.generate(docs.length, (i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final val = (data['value'] ?? 70) as num;
                    return FlSpot(i.toDouble(), val.toDouble());
                  });

                  final labels = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final ts = data['timestamp'] as Timestamp?;
                    return DateFormat(
                      'E',
                    ).format(ts?.toDate() ?? DateTime.now());
                  }).toList();

                  return _chartLayout(spots, labels);
                } catch (e) {
                  return const Center(
                    child: Text("Error rendering chart data"),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVitalsChart() {
    // Show a sample/placeholder chart for student demo if no data is found
    final spots = const [
      FlSpot(0, 72),
      FlSpot(1, 68),
      FlSpot(2, 75),
      FlSpot(3, 82),
      FlSpot(4, 70),
      FlSpot(5, 74),
      FlSpot(6, 78),
    ];
    final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Opacity(
      opacity: 0.5,
      child: Column(
        children: [
          Expanded(child: _chartLayout(spots, labels)),
          const Center(
            child: Text(
              "Connect wearable to sync live metrics",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLayout(List<FlSpot> spots, List<String> labels) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                if (v.toInt() >= 0 && v.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[v.toInt()],
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
            ),
            barWidth: 6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.15),
                  const Color(0xFF7C3AED).withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePulse() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.monitor_heart, color: Colors.red, size: 14),
          SizedBox(width: 6),
          Text(
            "LIVE PULSE",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _metricCard(
                title: "Blood Pressure",
                value: "118/76",
                unit: "mmHg",
                icon: Icons.favorite,
                color: Colors.pink,
              ),
              const SizedBox(height: 16),
              _metricCard(
                title: "Hydration Level",
                value: "85",
                unit: "% Daily",
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _metricCard(
                title: "Body Weight",
                value: "71.4",
                unit: "kg",
                icon: Icons.monitor_weight,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _metricCard(
                title: "Respiratory",
                value: "18",
                unit: "bpm",
                icon: Icons.air,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _exportPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing Clinical Data...")),
    );
    try {
      await PdfExportUtility.generateAndSaveMedicalReport(patientId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Clinical Report Downloaded")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export Error: $e")));
      }
    }
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
