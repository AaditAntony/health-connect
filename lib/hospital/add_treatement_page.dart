import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    return result?.files.first;
  }

  bool validImage(PlatformFile file) {
    return file.bytes != null && file.bytes!.lengthInBytes < 200 * 1024;
  }

  Future<void> saveTreatment() async {
    if (diagnosisController.text.isEmpty ||
        treatmentController.text.isEmpty) return;

    String? imageBase64;

    if (reportImage != null) {
      if (!validImage(reportImage!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image must be under 200 KB")),
        );
        return;
      }
      imageBase64 = base64Encode(reportImage!.bytes!);
    }

    await FirebaseFirestore.instance.collection('treatments').add({
      "patientId": widget.patientId,
      "hospitalId": widget.hospitalId,
      "diagnosis": diagnosisController.text.trim(),
      "treatmentPlan": treatmentController.text.trim(),
      "reportImageBase64": imageBase64,
      "createdAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Treatment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: diagnosisController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Diagnosis"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: treatmentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Treatment Plan"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                reportImage = await pickImage();
                setState(() {});
              },
              child: const Text("Upload Report Image (Optional)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTreatment,
              child: const Text("Save Treatment"),
            ),
          ],
        ),
      ),
    );
  }
}
