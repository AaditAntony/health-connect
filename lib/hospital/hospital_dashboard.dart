import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin/admin_auth_page.dart';
import 'add_patient_list.dart';

class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Dashboard"),
        actions: [
          IconButton(onPressed: () async {
            await FirebaseAuth.instance.signOut();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminAuthPage()),
                  (route) => false,
            );

          }, icon: Icon(Icons.circle_notifications_sharp))
        ],
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("View Patients"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientListPage(hospitalId: hospitalId),
              ),
            );
          },
        ),
      ),
    );
  }
}
