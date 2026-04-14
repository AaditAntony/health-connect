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
    "Ernakulam", "Thrissur", "Kozhikode", "Trivandrum", "Palakkad", "Kannur",
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
    return file.bytes != null && file.bytes!.lengthInBytes < 500 * 1024; // Increased to 500KB for better quality
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
      _showError("Please fill all fields and upload all required documents");
      return;
    }

    if (!isValidSize(profileImage!) ||
        !isValidSize(certificateImage!) ||
        !isValidSize(sealSignImage!)) {
      _showError("Each image must be under 500 KB");
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HospitalVerificationPage(),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Facility Registration",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Layout for Web: Two columns
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildFormSection(),
                          const SizedBox(height: 32),
                          _buildDocumentSection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Summary/Info panel
                    _buildInfoPanel(),
                  ],
                ),
                const SizedBox(height: 48),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Complete Your Hospital Profile",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Please provide accurate information for verification and onboarding.",
          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return _SectionCard(
      title: "Organization Details",
      icon: Icons.business_outlined,
      children: [
        _buildTextField(
          controller: nameController,
          label: "Registered Hospital Name",
          hint: "e.g., City General Hospital",
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: addressController,
          label: "Complete Address",
          hint: "Street address, Building, Suite",
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTextField(
                controller: yearController,
                label: "Year Established",
                hint: "YYYY",
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return _SectionCard(
      title: "Required Documentation",
      icon: Icons.file_present_outlined,
      children: [
        _buildDocPicker(
          title: "Facility Profile Image",
          subtitle: "Public facing photo of the hospital",
          file: profileImage,
          onPick: () => pickImage((f) => setState(() => profileImage = f)),
        ),
        const Divider(height: 32),
        _buildDocPicker(
          title: "Registration Certificate",
          subtitle: "Medical registration or business license",
          file: certificateImage,
          onPick: () => pickImage((f) => setState(() => certificateImage = f)),
        ),
        const Divider(height: 32),
        _buildDocPicker(
          title: "Seal & Authorized Signatory",
          subtitle: "Digital copy of hospital seal with signature",
          file: sealSignImage,
          onPick: () => pickImage((f) => setState(() => sealSignImage = f)),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF0891B2)),
            const SizedBox(height: 16),
            const Text(
              "Verification Process",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text(
              "After submission, our administrators will review your credentials. This typically takes 24-48 hours.",
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildInfoItem(Icons.check_circle_outline, "Valid Medical ID"),
            _buildInfoItem(Icons.check_circle_outline, "High-Res Documents"),
            _buildInfoItem(Icons.check_circle_outline, "Authorized Stamp"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF059669)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("District", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: district,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => district = v),
        ),
      ],
    );
  }

  Widget _buildDocPicker({
    required String title,
    required String subtitle,
    required PlatformFile? file,
    required VoidCallback onPick,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (file != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(file.bytes!, width: 80, height: 80, fit: BoxFit.cover),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: onPick,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.edit, size: 14, color: Color(0xFF0891B2)),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0891B2), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.upload_rounded, size: 18, color: Color(0xFF0891B2)),
                    SizedBox(width: 8),
                    Text("Upload", style: TextStyle(color: Color(0xFF0891B2), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 56,
        child: ElevatedButton(
          onPressed: submitProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0891B2),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            "Submit for Verification",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0891B2), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}
// ui