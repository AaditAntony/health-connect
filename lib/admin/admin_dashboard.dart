import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/web/admin_login_page.dart';
import '../core/responsive.dart';
import 'admin_auth_page.dart';
import 'hospital_detail_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"),actions: [
        IconButton(onPressed: () async {
          await FirebaseAuth.instance.signOut();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                (route) => false,
          );

        }, icon: Icon(Icons.circle_notifications_sharp))
      ],),
      body: ResponsiveWrapper(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('accounts')
              .where('role', isEqualTo: 'hospital')
              .where('approved', isEqualTo: false) // 👈 KEY LINE
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text("No hospitals pending approval"),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  child: ListTile(
                    title: Text(data['hospitalName'] ?? "Hospital"),
                    subtitle: const Text("Pending Verification"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HospitalDetailPage(hospitalId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
