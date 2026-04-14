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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "Beats Per Minute (BPM) tracking",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                          "Chart Error: Composite index required",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));

                final docs = snapshot.data!.docs.reversed.toList();

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
    return Column(
      children: [
        Expanded(child: Opacity(opacity: 0.3, child: _chartLayout(spots, labels))),
        const Center(
          child: Text(
            "Sync clinical data to view patterns",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartLayout(List<FlSpot> spots, List<String> labels) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        fontSize: 11,
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
              colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.1),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.monitor_heart_rounded, color: Color(0xFFEF4444), size: 14),
          SizedBox(width: 6),
          Text(
            "LIVE",
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: "Blood Pressure",
                value: "118/76",
                unit: "mmHg",
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _metricCard(
                title: "Body Weight",
                value: "71.4",
                unit: "kg",
                icon: Icons.monitor_weight_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: "Hydration",
                value: "85",
                unit: "%",
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _metricCard(
                title: "Respiratory",
                value: "18",
                unit: "bpm",
                icon: Icons.air_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _exportPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing Report...")),
    );
    try {
      await PdfExportUtility.generateAndSaveMedicalReport(patientId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report Saved Successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export Failed: $e")));
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
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
