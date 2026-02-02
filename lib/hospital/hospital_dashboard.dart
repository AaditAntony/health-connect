import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/responsive.dart';
import 'add_patient_page.dart';

class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final String hospitalId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ResponsiveWrapper(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome Hospital",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Add Patient"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPatientPage(hospitalId: hospitalId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
