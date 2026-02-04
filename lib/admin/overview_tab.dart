import 'package:flutter/material.dart';

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

          // -------- STAT CARDS --------
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(
                title: "Total Hospitals",
                value: "15",
                icon: Icons.local_hospital,
                color: Colors.blue,
              ),
              _statCard(
                title: "Total Patients",
                value: "3,456",
                icon: Icons.people,
                color: Colors.green,
              ),
              _statCard(
                title: "Pending Approvals",
                value: "3",
                icon: Icons.pending_actions,
                color: Colors.purple,
              ),
              _statCard(
                title: "Data Share Requests",
                value: "28",
                icon: Icons.share,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // -------- RECENT ACTIVITY --------
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
                    subtitle: "County Regional Hospital · 2 hours ago",
                  ),
                  Divider(),

                  _ActivityItem(
                    color: Colors.blue,
                    title: "Hospital approved",
                    subtitle: "University Health · 5 hours ago",
                  ),
                  Divider(),

                  _ActivityItem(
                    color: Colors.purple,
                    title: "Data sharing request processed",
                    subtitle:
                    "Memorial Hospital → Central Medical · 1 day ago",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------- STAT CARD --------
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
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
                    value,
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
        ),
      ),
    );
  }
}

// -------- ACTIVITY ITEM --------
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
