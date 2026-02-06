// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'add_patient_page.dart';
// import 'add_treatement_page.dart';
//
// class PatientListPage extends StatelessWidget {
//   final String hospitalId;
//
//   const PatientListPage({super.key, required this.hospitalId});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Patients"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       AddPatientPage(hospitalId: hospitalId),
//                 ),
//               );
//             },
//           )
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('patients')
//             .where('hospitalId', isEqualTo: hospitalId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final patients = snapshot.data!.docs;
//
//           if (patients.isEmpty) {
//             return const Center(child: Text("No patients found"));
//           }
//
//           return ListView.builder(
//             itemCount: patients.length,
//             itemBuilder: (context, index) {
//               final doc = patients[index];
//               final data = doc.data() as Map<String, dynamic>;
//
//               return Card(
//                 child: ListTile(
//                   title: Text(data['name']),
//                   subtitle:
//                   Text("Age: ${data['age']} | Blood: ${data['bloodGroup']}"),
//                   trailing: const Icon(Icons.medical_services),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => AddTreatmentPage(
//                           patientId: doc.id,
//                           hospitalId: hospitalId,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
