
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_connect/hospital/add_patient_page.dart';
import 'package:health_connect/hospital/patient_records_tab.dart';
import 'package:health_connect/web/hospital_login_page.dart';

import '../admin/admin_auth_page.dart';
import 'hospital_profile_page.dart';
import 'hospital_verification_page.dart';
import 'add_patient_list.dart';
import 'hospital_web_layout.dart';

class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital"),actions: [
        IconButton(onPressed: () async {
          await FirebaseAuth.instance.signOut();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HospitalLoginPage()),
                (route) => false,
          );

        }, icon: Icon(Icons.circle_notifications_sharp))
      ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('accounts')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          // 1️⃣ Profile not submitted
          if (!data.containsKey('hospitalName')) {
            return const HospitalProfilePage();
          }

          // 2️⃣ Submitted but not approved
          if (data['approved'] != true) {
            return const HospitalVerificationPage();
          }

          // 3️⃣ Approved → MAIN HOSPITAL DASHBOARD
          return HospitalWebLayout(
            currentTab: HospitalTab.patients,
            hospitalName: data['hospitalName'],
            hospitalId: uid,
            child: AddPatientPage(hospitalId: uid)
          );
        },
      ),
    );
  }
}

// import 'hospital_web_layout.dart';
//
// return HospitalWebLayout(
// currentTab: HospitalTab.overview,
// hospitalName: data['hospitalName'],
// hospitalId: uid,
// child: const Center(
// child: Text(
// "Overview content goes here",
// style: TextStyle(fontSize: 18),
// ),
// ),
// );