import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../web/web_login_choice_page.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WebLoginChoicePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text("Welcome Doctor! Dashboard coming soon."),
      ),
    );
  }
}
