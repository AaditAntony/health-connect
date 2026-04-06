import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class UploadTestResultPage extends StatefulWidget {
  final String appointmentId;
  final String patientId;
  final String hospitalId;
  final String testType;

  const UploadTestResultPage({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.hospitalId,
    required this.testType,
  });

  @override
  State<UploadTestResultPage> createState() => _UploadTestResultPageState();
}

class _UploadTestResultPageState extends State<UploadTestResultPage> {
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController(); // Used as "additional notes"

  PlatformFile? reportImage;
  bool isSubmitting = false;

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      setState(() => reportImage = result.files.first);
    }
  }

  Future<void> submit() async {
    if (diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diagnosis field cannot be empty.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('treatments').add({
        "patientId": widget.patientId,
        "hospitalId": widget.hospitalId,
        "diagnosis": "${widget.testType} Result: ${diagnosisController.text.trim()}",
        "treatmentPlan": treatmentController.text.trim().isEmpty ? "Review test results" : treatmentController.text.trim(),
        "reportImageBase64": reportImage != null ? base64Encode(reportImage!.bytes!) : null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Update appointment status to completed
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({'status': 'completed'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Test Results Uploaded!")),
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
        title: Text("Upload ${widget.testType} Result"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Result Details for ${widget.testType}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: diagnosisController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Test Result / Diagnosis",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: treatmentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Additional Notes / Recommendations",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload Report Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  
                  if (reportImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(reportImage!.name, style: const TextStyle(color: Colors.grey)),
                    ),
                    
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Results", style: TextStyle(color: Colors.white)),
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
