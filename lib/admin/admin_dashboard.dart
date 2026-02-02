import 'package:flutter/material.dart';
import '../core/responsive.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: ResponsiveWrapper(
        child: const Center(
          child: Text(
            "Admin Dashboard Loaded",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
