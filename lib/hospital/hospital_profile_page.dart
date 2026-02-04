import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/responsive.dart';
import 'hospital_verification_page.dart';

class HospitalProfilePage extends StatefulWidget {
  const HospitalProfilePage({super.key});

  @override
  State<HospitalProfilePage> createState() => _HospitalProfilePageState();
}

class _HospitalProfilePageState extends State<HospitalProfilePage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final yearController = TextEditingController();

  String? district;

  PlatformFile? profileImage;
  PlatformFile? certificateImage;
  PlatformFile? sealSignImage;

  final districts = [
    "Ernakulam",
    "Thrissur",
    "Kozhikode",
    "Trivandrum",
    "Palakkad",
    "Kannur",
  ];

  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    return result?.files.first;
  }

  bool isValidSize(PlatformFile file) {
    return file.bytes != null && file.bytes!.lengthInBytes < 200 * 1024;
  }

  String toBase64(PlatformFile file) {
    return base64Encode(file.bytes!);
  }

  Future<void> submitProfile() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        yearController.text.isEmpty ||
        district == null ||
        profileImage == null ||
        certificateImage == null ||
        sealSignImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    if (!isValidSize(profileImage!) ||
        !isValidSize(certificateImage!) ||
        !isValidSize(sealSignImage!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Images must be under 200 KB")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('accounts').doc(uid).set({
      "hospitalName": nameController.text.trim(),
      "address": addressController.text.trim(),
      "district": district,
      "establishedYear": yearController.text.trim(),

      "profileImageBase64": toBase64(profileImage!),
      "certificateBase64": toBase64(certificateImage!),
      "sealSignBase64": toBase64(sealSignImage!),
      "profileSubmitted": true,
      "approved": false,
      "role": "hospital",
    }, SetOptions(merge: true));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HospitalVerificationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospital Profile")),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Hospital Name"),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              DropdownButtonFormField<String>(
                value: district,
                decoration: const InputDecoration(labelText: "District"),
                items: districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => district = v),
              ),
              TextField(
                controller: yearController,
                decoration:
                const InputDecoration(labelText: "Year Established"),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  profileImage = await pickImage();
                  setState(() {});
                },
                child: const Text("Upload Profile Image"),
              ),

              ElevatedButton(
                onPressed: () async {
                  certificateImage = await pickImage();
                  setState(() {});
                },
                child: const Text("Upload Certificate"),
              ),

              ElevatedButton(
                onPressed: () async {
                  sealSignImage = await pickImage();
                  setState(() {});
                },
                child: const Text("Upload Seal + Sign"),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: submitProfile,
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
