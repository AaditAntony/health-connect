import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> pickImage(Function(PlatformFile) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      onPicked(result.files.first);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Hospital Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 700,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hospital Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration:
                    const InputDecoration(labelText: "Hospital Name"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Address"),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: district,
                    decoration: const InputDecoration(labelText: "District"),
                    items: districts
                        .map(
                          (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => district = v),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: yearController,
                    decoration:
                    const InputDecoration(labelText: "Year Established"),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Required Documents",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _imagePicker(
                    title: "Hospital Profile Image",
                    file: profileImage,
                    onPick: () => pickImage((f) {
                      setState(() => profileImage = f);
                    }),
                  ),

                  _imagePicker(
                    title: "Hospital Certificate",
                    file: certificateImage,
                    onPick: () => pickImage((f) {
                      setState(() => certificateImage = f);
                    }),
                  ),

                  _imagePicker(
                    title: "Seal & Authorized Signature",
                    file: sealSignImage,
                    onPick: () => pickImage((f) {
                      setState(() => sealSignImage = f);
                    }),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child:  Text("Submit for Verification",style:TextStyle(color: Colors.white) ,),
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

  // ================= IMAGE PICKER WIDGET =================

  Widget _imagePicker({
    required String title,
    required PlatformFile? file,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload),
                label: const Text("Upload"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    file.bytes!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
