import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddScanPage extends StatefulWidget {
  final String patientId;

  const AddScanPage({super.key, required this.patientId});

  @override
  State<AddScanPage> createState() => _AddScanPageState();
}

class _AddScanPageState extends State<AddScanPage> {
  final _formKey = GlobalKey<FormState>();
  final _scanInfoController = TextEditingController();
  final _observationsController = TextEditingController();

  String scanType = "X-Ray";
  bool isSubmitting = false;

  final List<String> scanTypes = [
    "X-Ray",
    "MRI Scan",
    "CT Scan",
    "Ultrasound",
    "PET Scan",
    "ECG",
    "Blood Test"
  ];

  Future<void> _submitScan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get doctor data for the record
      final docDataSnapshot = await FirebaseFirestore.instance.collection('accounts').doc(user.uid).get();
      final doctorName = docDataSnapshot.data()?['doctorName'] ?? "Unknown Doctor";
      final hospitalId = docDataSnapshot.data()?['hospitalId'];

      await FirebaseFirestore.instance.collection('scans').add({
        'patientId': widget.patientId,
        'doctorId': user.uid,
        'doctorName': doctorName,
        'hospitalId': hospitalId,
        'scanType': scanType,
        'scanInfo': _scanInfoController.text.trim(),
        'observations': _observationsController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Scan record added successfully")),
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
        title: const Text("Add Scan Record"),
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
              const Text("Scan Type", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: scanType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: scanTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => scanType = v!),
              ),
              const SizedBox(height: 24),

              const Text("Scan Info / Region", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _scanInfoController,
                decoration: InputDecoration(
                  hintText: "E.g. Chest X-Ray or Left Knee MRI",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),

              const Text("Observations / Results", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observationsController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter your observations and findings from the scan result.",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: isSubmitting ? null : _submitScan,
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
