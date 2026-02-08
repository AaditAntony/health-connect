import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/patient/patient_dashboard.dart';

enum LinkMethod { phone, patientId }

class PatientLinkPage extends StatefulWidget {
  const PatientLinkPage({super.key});

  @override
  State<PatientLinkPage> createState() => _PatientLinkPageState();
}

class _PatientLinkPageState extends State<PatientLinkPage> {
  final phoneController = TextEditingController();
  final patientIdController = TextEditingController();

  LinkMethod method = LinkMethod.phone;
  bool loading = false;

  Future<void> linkPatient() async {
    setState(() => loading = true);

    final authUid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot? patientDoc;

    try {
      // -------- LINK USING PHONE --------
      if (method == LinkMethod.phone) {
        if (phoneController.text.trim().isEmpty) {
          throw "Please enter phone number";
        }

        final query = await FirebaseFirestore.instance
            .collection('patients')
            .where('phone', isEqualTo: phoneController.text.trim())
            .get();

        if (query.docs.length != 1) {
          throw "Patient record not found or multiple records found";
        }

        patientDoc = query.docs.first;
      }

      // -------- LINK USING PATIENT ID --------
      if (method == LinkMethod.patientId) {
        if (patientIdController.text.trim().isEmpty) {
          throw "Please enter Patient ID";
        }

        final doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientIdController.text.trim())
            .get();

        if (!doc.exists) {
          throw "Invalid Patient ID";
        }

        patientDoc = doc;
      }

      // -------- SAVE LINK (ONE TIME) --------
      await FirebaseFirestore.instance
          .collection('patient_users')
          .doc(authUid)
          .set({
        "authUid": authUid,
        "patientId": patientDoc!.id,
        "linkedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medical record linked successfully")),

      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=> PatientDashboard()  ));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4C1D95),
        title: const Text(
          "Link Medical Record",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 4,
            shadowColor: const Color(0xFF7C3AED).withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- TITLE --------
                  const Text(
                    "Link your medical record",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C1D95),
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    "Securely connect your hospital records to view your medical history.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // -------- RADIO GROUP --------
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDDD6FE),
                      ),
                    ),
                    child: RadioGroup<LinkMethod>(
                      groupValue: method,
                      onChanged: (value) {
                        setState(() => method = value!);
                      },
                      child: Column(
                        children: const [
                          RadioListTile(
                            value: LinkMethod.phone,
                            activeColor: Color(0xFF7C3AED),
                            title: Text("Link using Phone Number"),
                          ),
                          Divider(height: 1),
                          RadioListTile(
                            value: LinkMethod.patientId,
                            activeColor: Color(0xFF7C3AED),
                            title: Text(
                              "Link using Patient ID (from bill)",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // -------- INPUT FIELD --------
                  if (method == LinkMethod.phone)
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        filled: true,
                        fillColor: const Color(0xFFFDFBFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  if (method == LinkMethod.patientId)
                    TextField(
                      controller: patientIdController,
                      decoration: InputDecoration(
                        labelText: "Patient ID",
                        hintText: "Example: AbC123Xyz",
                        filled: true,
                        fillColor: const Color(0xFFFDFBFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 26),

                  // -------- ACTION BUTTON --------
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : linkPatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        loading ? "Linking..." : "Link Record",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );


  }
}
