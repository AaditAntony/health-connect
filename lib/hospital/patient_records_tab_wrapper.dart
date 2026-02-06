import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_records_tab.dart';

class PatientRecordsTabWrapper extends StatelessWidget {
  const PatientRecordsTabWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;
    return PatientRecordsTab(hospitalId: hospitalId);
  }
}
