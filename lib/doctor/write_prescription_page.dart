import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WritePrescriptionPage extends StatefulWidget {
  final String appointmentId;
  final String patientId;

  const WritePrescriptionPage({
    super.key,
    required this.appointmentId,
    required this.patientId,
  });

  @override
  State<WritePrescriptionPage> createState() => _WritePrescriptionPageState();
}

class _WritePrescriptionPageState extends State<WritePrescriptionPage> {
  final _medicinesController = TextEditingController();
  final _activitiesController = TextEditingController();
  bool isSubmitting = false;

  void _submit() async {
    if (_medicinesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write some medicines.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('prescriptions').add({
        'appointmentId': widget.appointmentId,
        'patientId': widget.patientId,
        'medicines': _medicinesController.text.trim(),
        'activities': _activitiesController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update appointment to 'completed'
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({'status': 'completed'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription uploaded successfully!")),
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
        title: const Text("Write Prescription"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Prescribed Medicines", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _medicinesController,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "E.g., Paracetamol 500mg - 1 tab after meals...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("Recommended Activities (Diet/Exercise)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _activitiesController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "E.g., 30 mins brisk walking, low sodium diet...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save & Complete Appointment", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
