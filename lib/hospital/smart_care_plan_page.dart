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

  List<TextEditingController> doctorNameControllers = [];
  List<TextEditingController> departmentControllers = [];

  bool loading = false;
  String? existingPlanId;

  @override
  void initState() {
    super.initState();
    doctorCountController.addListener(_updateDoctorFields);
    _loadExistingPlan();
  }

  // ---------------- DYNAMIC DOCTOR FIELDS ----------------

  void _updateDoctorFields() {
    final count = int.tryParse(doctorCountController.text) ?? 0;

    if (count < 0) return;

    setState(() {
      doctorNameControllers =
          List.generate(count, (_) => TextEditingController());
      departmentControllers =
          List.generate(count, (_) => TextEditingController());
    });
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

      existingPlanId = doc.id;

      amountController.text = data['amount'].toString();
      doctorCountController.text = data['doctorCount'].toString();
      descriptionController.text = data['description'];

      final doctors = List<Map<String, dynamic>>.from(data['doctors']);

      doctorNameControllers =
          List.generate(doctors.length, (i) {
            return TextEditingController(text: doctors[i]['name']);
          });

      departmentControllers =
          List.generate(doctors.length, (i) {
            return TextEditingController(text: doctors[i]['department']);
          });

      setState(() {});
    }
  }

  // ---------------- SAVE PLAN ----------------

  Future<void> savePlan() async {
    final count = int.tryParse(doctorCountController.text) ?? 0;

    if (amountController.text.isEmpty ||
        doctorCountController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        doctorNameControllers.length != count) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields correctly")),
      );
      return;
    }

    setState(() => loading = true);

    final hospitalId = FirebaseAuth.instance.currentUser!.uid;

    try {
      List<Map<String, dynamic>> doctors = [];

      for (int i = 0; i < count; i++) {
        if (doctorNameControllers[i].text.isEmpty ||
            departmentControllers[i].text.isEmpty) {
          throw "Fill all doctor details";
        }

        doctors.add({
          "name": doctorNameControllers[i].text.trim(),
          "department": departmentControllers[i].text.trim(),
        });
      }

      final data = {
        "amount": int.parse(amountController.text.trim()),
        "doctorCount": count,
        "description": descriptionController.text.trim(),
        "doctors": doctors,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: SizedBox(
            width: 700,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- HEADER LOGO ----------------
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF5B21B6),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "SmartCarePlan",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Create subscription plans for your patients",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Create SmartCarePlan",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _input("Monthly Amount (₹)"),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: doctorCountController,
                      keyboardType: TextInputType.number,
                      decoration: _input("Number of Doctors"),
                    ),

                    const SizedBox(height: 24),

                    // -------- DYNAMIC DOCTORS --------
                    for (int i = 0;
                    i < doctorNameControllers.length;
                    i++)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Doctor ${i + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: doctorNameControllers[i],
                            decoration: _input("Doctor Name"),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: departmentControllers[i],
                            decoration: _input("Department"),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: _input("Plan Description"),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : savePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
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
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
