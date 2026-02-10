import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../hospital/hospital_dashboard.dart';
import '../hospital/hospital_profile_page.dart';
import '../hospital/hospital_verification_page.dart';
import '../patient/patient_auth_page.dart';
import '../patient/patient_dashboard.dart';
import '../patient/patient_link_page.dart';
import '../web/web_login_choice_page.dart';
import 'admin_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _entryGate();
        }

        return _routeAfterLogin(snapshot.data!);
      },
    );
  }

  // ---------------- ENTRY GATE ----------------

  Widget _entryGate() {
    if (kIsWeb) {
      return const WebLoginChoicePage();
    } else {
      return const PatientAuthPage();
    }
  }

  // ---------------- POST LOGIN ROUTING ----------------

  Widget _routeAfterLogin(User user) {
    if (kIsWeb) {
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
            return _blockedPage(
              "Patient access is available only on the mobile app.",
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'];

          // ---------- ADMIN ----------
          if (role == 'admin') {
            if (data['approved'] == true) {
              return const AdminDashboard();
            } else {
              return _blockedPage("Admin approval pending.");
            }
          }

          // ---------- HOSPITAL ----------
          if (role == 'hospital') {
            final bool profileSubmitted =
                data['profileSubmitted'] == true;
            final bool approved = data['approved'] == true;

            // 1️⃣ Profile not submitted
            if (!profileSubmitted) {
              return const HospitalProfilePage();
            }

            // 2️⃣ Profile submitted, waiting for admin approval
            if (profileSubmitted && !approved) {
              return const HospitalVerificationPage();
            }

            // 3️⃣ Approved hospital
            if (approved) {
              return const HospitalDashboard();
            }
          }

          return _blockedPage("Access denied.");
        },
      );
    }

    // ---------------- MOBILE (PATIENT) ----------------

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
          return const PatientLinkPage();
        }

        return const PatientDashboard();
      },
    );
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
