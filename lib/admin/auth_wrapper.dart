import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../hospital/hospital_dashboard.dart';

import 'admin_auth_page.dart';
import 'admin_dashboard.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Not logged in
        if (!snapshot.hasData) {
          return const AdminAuthPage();
        }

        // Logged in → check role
        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('accounts')
              .doc(uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
            roleSnapshot.data!.data() as Map<String, dynamic>;

            if (data['role'] == 'admin') {
              return const AdminDashboard();
            } else {
              return const HospitalDashboard();
            }
          },
        );
      },
    );
  }
}
