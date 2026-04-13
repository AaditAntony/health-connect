import 'package:flutter/foundation.dart'; // import kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../doctor/doctor_dashboard.dart';
import '../hospital/hospital_dashboard.dart';
import '../hospital/hospital_profile_page.dart';
import '../hospital/hospital_verification_page.dart';
import '../patient/patient_dashboard.dart';
import '../patient/patient_link_page.dart';
import '../patient/patient_auth_page.dart'; // Import patient auth page
import '../web/web_login_choice_page.dart';
import 'admin_dashboard.dart';
import '../doctor/doctor_profile_page.dart';
import '../doctor/doctor_verification_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Scaffold(body: Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center)));
        }
        if (!snapshot.hasData) {
          if (kIsWeb) {
            return const WebLoginChoicePage();
          } else {
            return const PatientAuthPage();
          }
        }

        return _routeAfterLogin(snapshot.data!);
      },
    );
  }

  // ---------------- POST LOGIN ROUTING ----------------

  Widget _routeAfterLogin(User user) {
    // We check `patient_users` first.
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('patient_users')
          .doc(user.uid)
          .get(),
      builder: (context, patientSnapshot) {
        if (patientSnapshot.hasError) {
          debugPrint("Error: ${patientSnapshot.error}");
          return Scaffold(body: Center(child: Text("Error: \n${patientSnapshot.error}", textAlign: TextAlign.center)));
        }
        if (patientSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is a patient, route them to patient flow
        if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
          if (kIsWeb) return _blockedPage("Patient access is restricted to the mobile app.");
          return const PatientDashboard();
        }

        // If not a patient, they might be an Admin, Hospital, or Doctor.
        // Or they might be a newly registered Patient who hasn't linked yet!
        // Wait, patient registration does sign out, but if they login and don't exist in `patient_users`?
        // Ah, `PatientAuthPage` creates the auth user but doesn't create `patient_users` doc until `PatientLinkPage`.
        // Let's check `accounts` collection to see if they are Admin/Hospital/Doctor.
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('accounts')
              .doc(user.uid)
              .get(),
          builder: (context, accountSnapshot) {
        if (accountSnapshot.hasError) {
          debugPrint("Error: ${accountSnapshot.error}");
          return Scaffold(body: Center(child: Text("Error: \n${accountSnapshot.error}", textAlign: TextAlign.center)));
        }
            if (accountSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (accountSnapshot.hasData && accountSnapshot.data!.exists) {
              final data = accountSnapshot.data!.data() as Map<String, dynamic>;
              final role = data['role'];

              if (!kIsWeb && (role == 'admin' || role == 'hospital' || role == 'doctor')) {
                return _blockedPage("${role[0].toUpperCase()}${role.substring(1)} access is restricted to the Web platform.");
              }

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
                final bool profileSubmitted = data['profileSubmitted'] == true;
                final bool approved = data['approved'] == true;

                if (!profileSubmitted) return const HospitalProfilePage();
                if (profileSubmitted && !approved) return const HospitalVerificationPage();
                if (approved) return const HospitalDashboard();
              }

              // ---------- DOCTOR ----------
              if (role == 'doctor') {
                final bool profileSubmitted = data['profileSubmitted'] == true;
                final bool approved = data['approved'] == true;

                if (!profileSubmitted) return const DoctorProfilePage();
                if (profileSubmitted && !approved) return const DoctorVerificationPage();
                if (approved) return const DoctorDashboard();
              }

              return _blockedPage("Invalid role assigned.");
            }

            // If not in `accounts`, they must be a Patient needing to link their ID.
            if (kIsWeb) return _blockedPage("Patient registration is restricted to the mobile app.");
            return const PatientLinkPage();
          },
        );
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
              const Icon(Icons.block, size: 60, color: Colors.blueGrey),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text("Sign Out"),
              )
            ],
          ),
        ),
      ),
    );
  }
}