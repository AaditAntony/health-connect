import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HospitalOverviewTab extends StatelessWidget {
  const HospitalOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // ================= STAT CARDS =================
          _buildStatisticsGrid(hospitalId),

          const SizedBox(height: 32),

          // ================= CHARTS SECTION =================
          const Text(
            "CLINICAL INSIGHTS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _PatientTrendChart(hospitalId: hospitalId)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _ServiceMixChart(hospitalId: hospitalId)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _PatientTrendChart(hospitalId: hospitalId),
                    const SizedBox(height: 24),
                    _ServiceMixChart(hospitalId: hospitalId),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 32),

          // ================= QUICK INFO =================
          _buildQuickActionsCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Hospital Intelligence",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Real-time monitoring and clinical performance metrics.",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(String hospitalId) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          title: "Total Patients",
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF3B82F6),
          stream: FirebaseFirestore.instance
              .collection('patients')
              .where('hospitalId', isEqualTo: hospitalId)
              .snapshots(),
        ),
        _StatCard(
          title: "Total Treatments",
          icon: Icons.medical_information_rounded,
          color: const Color(0xFF10B981),
          stream: FirebaseFirestore.instance
              .collection('treatments')
              .where('hospitalId', isEqualTo: hospitalId)
              .snapshots(),
        ),
        _StatCard(
          title: "Active Scans",
          icon: Icons.biotech_rounded,
          color: const Color(0xFFF59E0B),
          stream: FirebaseFirestore.instance
              .collection('scans')
              .where('hospitalId', isEqualTo: hospitalId)
              .snapshots(),
        ),
        _ApprovalStatusCard(hospitalId: hospitalId),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
              SizedBox(width: 12),
              Text(
                "Operational Quick Notes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "• Patient records are automatically synced with national registry.\n"
            "• AI Summaries are generated daily for critical cases.\n"
            "• Data transfers are encrypted and require patient consent.\n"
            "• Emergency requests bypass standard verification delays.",
            style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ================= STAT CARD =================

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
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================= APPROVAL STATUS CARD =================

class _ApprovalStatusCard extends StatelessWidget {
  final String hospitalId;
  const _ApprovalStatusCard({required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('accounts').doc(hospitalId).snapshots(),
        builder: (context, snapshot) {
          final isApproved = snapshot.hasData && (snapshot.data!.data() as Map?)?['approved'] == true;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isApproved ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isApproved ? Icons.verified_user_rounded : Icons.pending_rounded,
                  color: isApproved ? Colors.green : Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isApproved ? "Verified" : "Pending",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const Text(
                "SYSTEM STATUS",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================= CHARTS =================

class _PatientTrendChart extends StatelessWidget {
  final String hospitalId;
  const _PatientTrendChart({required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PATIENT REGISTRATION TREND (LAST 7 DAYS)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .where('hospitalId', isEqualTo: hospitalId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // Logic: Count patients per day for last 7 days
                final now = DateTime.now();
                Map<String, int> dailyCounts = {};
                for (int i = 0; i < 7; i++) {
                  final date = now.subtract(Duration(days: i));
                  dailyCounts[DateFormat('MM/dd').format(date)] = 0;
                }

                for (var doc in snapshot.data!.docs) {
                  final ts = doc['createdAt'] as Timestamp?;
                  if (ts != null) {
                    final day = DateFormat('MM/dd').format(ts.toDate());
                    if (dailyCounts.containsKey(day)) {
                      dailyCounts[day] = dailyCounts[day]! + 1;
                    }
                  }
                }

                final sortedKeys = dailyCounts.keys.toList().reversed.toList();
                final spots = List.generate(sortedKeys.length, (i) {
                  return FlSpot(i.toDouble(), dailyCounts[sortedKeys[i]]!.toDouble());
                });

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade50, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            if (v.toInt() >= 0 && v.toInt() < sortedKeys.length) {
                              return Padding(padding: const EdgeInsets.only(top: 8), child: Text(sortedKeys[v.toInt()], style: const TextStyle(fontSize: 9, color: Colors.grey)));
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
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.1), const Color(0xFF6366F1).withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceMixChart extends StatelessWidget {
  final String hospitalId;
  const _ServiceMixChart({required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SERVICE DISTRIBUTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('treatments').where('hospitalId', isEqualTo: hospitalId).snapshots(),
              builder: (context, treatSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('scans').where('hospitalId', isEqualTo: hospitalId).snapshots(),
                  builder: (context, scanSnapshot) {
                    if (!treatSnapshot.hasData || !scanSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final treats = treatSnapshot.data!.docs.length.toDouble();
                    final scans = scanSnapshot.data!.docs.length.toDouble();
                    final total = treats + scans;

                    if (total == 0) return const Center(child: Text("No Data", style: TextStyle(color: Colors.grey)));

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(color: const Color(0xFF10B981), value: treats, radius: 15, showTitle: false),
                              PieChartSectionData(color: const Color(0xFF3B82F6), value: scans, radius: 15, showTitle: false),
                            ],
                            centerSpaceRadius: 50,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(total.toInt().toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                            const Text("TOTAL", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ],
                    );
                  }
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _indicator(const Color(0xFF10B981), "Treatments"),
          const SizedBox(height: 8),
          _indicator(const Color(0xFF3B82F6), "Special Scans"),
        ],
      ),
    );
  }

  Widget _indicator(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }
}
