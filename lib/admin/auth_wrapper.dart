import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../hospital/hospital_dashboard.dart';
import '../patient/patient_auth_page.dart';
import '../patient/patient_link_page.dart';
import 'admin_auth_page.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Not logged in
        if (!snapshot.hasData) {
          return _entryGate();
        }

        final user = snapshot.data!;
        return _routeAfterLogin(user);
      },
    );
  }

  // ---------------- ENTRY GATE ----------------

  Widget _entryGate() {
    if (kIsWeb) {
      // Web → Admin / Hospital only
      return const AdminAuthPage();
    } else {
      // Mobile → Patient only
      return const PatientAuthPage();
    }
  }

  // ---------------- POST LOGIN ROUTING ----------------

  Widget _routeAfterLogin(User user) {
    if (kIsWeb) {
      // WEB LOGIN FLOW
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('accounts')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.data!.exists) {
            // Patient trying to access web
            return _blockedPage(
              "Patient access is available only on the mobile app.",
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'];

          if (role == 'admin' || role == 'hospital') {
            return const HospitalDashboard();
          }

          return _blockedPage(
            "Access denied for this account on web.",
          );
        },
      );
    } else {
      // MOBILE LOGIN FLOW (Patient only)
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('patient_users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.data!.exists) {
            // Patient logged in but not linked
            return const PatientLinkPage();
          }

          // Linked patient → dashboard comes next (Phase 3)
          return _blockedPage(
            "Patient dashboard will be shown here next.",
          );
        },
      );
    }
  }

  // ---------------- BLOCKED PAGE ----------------

  Widget _blockedPage(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
