import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/responsive.dart';

class HospitalDetailPage extends StatelessWidget {
  final String hospitalId;

  const HospitalDetailPage({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospital Verification")),
      body: ResponsiveWrapper(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('accounts')
              .doc(hospitalId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.data() == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final data =
            snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital profile image
                  if (data['profileImageBase64'] != null)
                    Image.memory(
                      base64Decode(data['profileImageBase64']),
                      height: 150,
                    ),

                  const SizedBox(height: 20),

                  Text(
                    data['hospitalName'] ?? "No name",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text("Address: ${data['address']}"),
                  Text("District: ${data['district']}"),
                  Text("Established Year: ${data['establishedYear']}"),

                  const SizedBox(height: 20),

                  const Text(
                    "Hospital Certificate",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (data['certificateBase64'] != null)
                    Image.memory(
                      base64Decode(data['certificateBase64']),
                      height: 150,
                    )
                  else
                    const Text("Certificate not uploaded"),

                  const SizedBox(height: 30),

                  // APPROVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('accounts')
                            .doc(hospitalId)
                            .update({"approved": true});

                        Navigator.pop(context);
                      },
                      child: const Text("Approve Hospital"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // REJECT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('accounts')
                            .doc(hospitalId)
                            .delete();

                        Navigator.pop(context);
                      },
                      child: const Text("Reject Hospital"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
