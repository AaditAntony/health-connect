import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartCarePlanPage extends StatefulWidget {
  const SmartCarePlanPage({super.key});

  @override
  State<SmartCarePlanPage> createState() => _SmartCarePlanPageState();
}

class _SmartCarePlanPageState extends State<SmartCarePlanPage> {
  final amountController = TextEditingController();
  final doctorCountController = TextEditingController();
  final descriptionController = TextEditingController();

  bool loading = false;
  String? existingPlanId;

  @override
  void initState() {
    super.initState();
    _loadExistingPlan();
  }

  // ---------------- LOAD EXISTING PLAN ----------------

  Future<void> _loadExistingPlan() async {
    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection('smartcareplans')
        .where('createdByHospitalId', isEqualTo: hospitalId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();

      setState(() {
        existingPlanId = doc.id;
        amountController.text = data['amount'].toString();
        doctorCountController.text = data['doctorCount'].toString();
        descriptionController.text = data['description'];
      });
    }
  }

  // ---------------- SAVE PLAN ----------------

  Future<void> savePlan() async {
    if (amountController.text.isEmpty ||
        doctorCountController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final data = {
        "amount": int.parse(amountController.text.trim()),
        "doctorCount": int.parse(doctorCountController.text.trim()),
        "description": descriptionController.text.trim(),
        "createdByHospitalId": hospitalId,
        "createdAt": Timestamp.now(),
      };

      if (existingPlanId == null) {
        await FirebaseFirestore.instance
            .collection('smartcareplans')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('smartcareplans')
            .doc(existingPlanId)
            .update(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SmartCarePlan saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("SmartCarePlan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 60,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Create SmartCarePlan",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -------- AMOUNT --------
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Monthly Amount (₹)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -------- DOCTOR COUNT --------
                  TextField(
                    controller: doctorCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of Doctors",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -------- DESCRIPTION --------
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Plan Description",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        loading ? "Saving..." : "Save Plan",
                        style: const TextStyle(color: Colors.white),
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
