import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
