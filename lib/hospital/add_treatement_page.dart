import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class AddTreatmentPage extends StatefulWidget {
  final String patientId;
  final String hospitalId;

  const AddTreatmentPage({
    super.key,
    required this.patientId,
    required this.hospitalId,
  });

  @override
  State<AddTreatmentPage> createState() => _AddTreatmentPageState();
}

class _AddTreatmentPageState extends State<AddTreatmentPage> {
  final diagnosisController = TextEditingController();
  final treatmentController = TextEditingController();

  PlatformFile? reportImage;

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
    if (diagnosisController.text.isEmpty ||
        treatmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('treatments').add({
      "patientId": widget.patientId,
      "hospitalId": widget.hospitalId,
      "diagnosis": diagnosisController.text.trim(),
      "treatmentPlan": treatmentController.text.trim(),
      "reportImageBase64": reportImage != null
          ? base64Encode(reportImage!.bytes!)
          : null,
      "createdAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Add Treatment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Treatment Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: diagnosisController,
                    maxLines: 4,
                    decoration:
                    const InputDecoration(labelText: "Diagnosis Report"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: treatmentController,
                    maxLines: 4,
                    decoration:
                    const InputDecoration(labelText: "Treatment Plan"),
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
                      child: Text(
                        reportImage!.name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: const Text("Save Treatment"),
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
