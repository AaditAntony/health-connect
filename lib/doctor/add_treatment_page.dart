import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTreatmentPage extends StatefulWidget {
  final String patientId;

  const AddTreatmentPage({super.key, required this.patientId});

  @override
  State<AddTreatmentPage> createState() => _AddTreatmentPageState();
}

class _AddTreatmentPageState extends State<AddTreatmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool isSubmitting = false;

  Future<void> _submitTreatment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get doctor data for the record
      final docDataSnapshot = await FirebaseFirestore.instance.collection('accounts').doc(user.uid).get();
      final doctorName = docDataSnapshot.data()?['doctorName'] ?? "Unknown Doctor";
      final hospitalId = docDataSnapshot.data()?['hospitalId'];

      await FirebaseFirestore.instance.collection('treatments').add({
        'patientId': widget.patientId,
        'doctorId': user.uid,
        'doctorName': doctorName,
        'hospitalId': hospitalId,
        'diagnosis': _diagnosisController.text.trim(),
        'treatmentPlan': _treatmentPlanController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Treatment record added successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Record Treatment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Diagnosis", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _diagnosisController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Enter diagnosis",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),

              const Text("Treatment Plan", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _treatmentPlanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe treatment plan",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),

              const Text("Medications", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medicationsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "List prescribed medications",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: isSubmitting ? null : _submitTreatment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Record",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
