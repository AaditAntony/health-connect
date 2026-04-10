import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_verification_page.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _experienceController = TextEditingController();

  String? selectedHospitalId;
  String? selectedHospitalName;
  String selectedDepartment = "General Medicine";

  PlatformFile? profileImage;
  PlatformFile? certificateImage;

  bool isSubmitting = false;

  final List<String> departments = [
    "General Medicine",
    "Cardiology",
    "Oncology",
    "Pediatrics",
    "Neurology",
    "Orthopedics",
    "Dermatology",
    "Radiology"
  ];

  Future<void> _pickFile(Function(PlatformFile) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      if (file.size > 300 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File size must be under 300 KB")),
        );
        return;
      }
      onPicked(file);
    }
  }

  String _toBase64(PlatformFile file) {
    return base64Encode(file.bytes!);
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate() || 
        selectedHospitalId == null || 
        profileImage == null || 
        certificateImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload required documents")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('accounts').doc(user.uid).update({
        'doctorName': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'experience': int.parse(_experienceController.text.trim()),
        'department': selectedDepartment,
        'hospitalId': selectedHospitalId,
        'hospitalName': selectedHospitalName,
        'profileImageBase64': _toBase64(profileImage!),
        'certificateBase64': _toBase64(certificateImage!),
        'profileSubmitted': true,
        'approved': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile submitted for Admin approval!")),
      );

      // Redirect to verification pending page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorVerificationPage()),
      );
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
        title: const Text("Complete Doctor Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Professional Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Fill in your details and upload your credentials.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              _buildTextField(_nameController, "Full Name (e.g. Dr. John Doe)", Icons.person),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildTextField(_ageController, "Age", Icons.cake, isNum: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_experienceController, "Exp (Years)", Icons.work, isNum: true)),
                ],
              ),
              const SizedBox(height: 20),

              _buildDropdown(),
              const SizedBox(height: 20),

              _buildHospitalSelect(),
              const SizedBox(height: 32),

              const Text("Verification Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Required for platform approval (Max 300KB each)", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),

              _buildImagePicker("Official Profile Photo", profileImage, (file) => setState(() => profileImage = file)),
              const SizedBox(height: 16),
              _buildImagePicker("Medical Registration Certificate", certificateImage, (file) => setState(() => certificateImage = file)),
              
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: isSubmitting ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Submit Profile for Approval", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNum = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDepartment,
      decoration: InputDecoration(
        labelText: "Department",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF7C3AED)),
      ),
      items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
      onChanged: (v) => setState(() => selectedDepartment = v!),
    );
  }

  Widget _buildHospitalSelect() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accounts')
          .where('role', isEqualTo: 'hospital')
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final hospitals = snapshot.data?.docs ?? [];
        return DropdownButtonFormField<String>(
          value: selectedHospitalId,
          decoration: InputDecoration(
            hintText: "Choose Working Hospital",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.business, color: Color(0xFF7C3AED)),
          ),
          items: hospitals.map((h) {
            final data = h.data() as Map<String, dynamic>;
            return DropdownMenuItem(value: h.id, child: Text(data['hospitalName'] ?? "Unnamed"));
          }).toList(),
          onChanged: (v) {
            setState(() {
              selectedHospitalId = v;
              final selectedDoc = hospitals.firstWhere((doc) => doc.id == v);
              selectedHospitalName = (selectedDoc.data() as Map<String, dynamic>)['hospitalName'];
            });
          },
        );
      },
    );
  }

  Widget _buildImagePicker(String title, PlatformFile? file, Function(PlatformFile) onPicked) {
    return InkWell(
      onTap: () => _pickFile(onPicked),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(file != null ? Icons.check_circle : Icons.cloud_upload_outlined, color: file != null ? Colors.green : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(file != null ? file.name : "Tap to upload image", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(file.bytes!, width: 40, height: 40, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }
}
