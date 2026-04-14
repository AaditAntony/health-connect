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
    "General Medicine", "Cardiology", "Oncology", "Pediatrics", 
    "Neurology", "Orthopedics", "Dermatology", "Radiology"
  ];

  Future<void> _pickFile(Function(PlatformFile) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      if (file.size > 500 * 1024) { // Increased to 500KB
        if (!mounted) return;
        _showError("File size must be under 500 KB");
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
      _showError("Please fill all fields and upload required documents");
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
        const SnackBar(
          content: Text("Profile submitted for Admin approval!"),
          backgroundColor: Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorVerificationPage()),
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
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
    const primaryColor = Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Practitioner Onboarding",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, size: 18, color: Color(0xFFE11D48)),
            label: const Text("Logout", style: TextStyle(color: Color(0xFFE11D48))),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildProfessionalSection(primaryColor),
                            const SizedBox(height: 32),
                            _buildDocumentSection(primaryColor),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      _buildInfoPanel(primaryColor),
                    ],
                  ),
                  const SizedBox(height: 48),
                  _buildSubmitButton(primaryColor),
                ],
              ),
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
          "Complete Your Professional Profile",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Join our network by providing your clinical credentials and affiliations.",
          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildProfessionalSection(Color primaryColor) {
    return _SectionCard(
      title: "Professional Details",
      icon: Icons.badge_outlined,
      primaryColor: primaryColor,
      children: [
        _buildTextField(
          controller: _nameController,
          label: "Full Name & Title",
          hint: "e.g., Dr. Jane Smith",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: "Age",
                hint: "Years",
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTextField(
                controller: _experienceController,
                label: "Experience",
                hint: "Years",
                icon: Icons.history_edu_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDropdown(primaryColor),
        const SizedBox(height: 20),
        _buildHospitalSelect(primaryColor),
      ],
    );
  }

  Widget _buildDocumentSection(Color primaryColor) {
    return _SectionCard(
      title: "Verification Documents",
      icon: Icons.verified_user_outlined,
      primaryColor: primaryColor,
      children: [
        _buildDocPicker(
          title: "Professional Headshot",
          subtitle: "Clear photo for your digital badge",
          file: profileImage,
          onPick: () => _pickFile((f) => setState(() => profileImage = f)),
          primaryColor: primaryColor,
        ),
        const Divider(height: 32),
        _buildDocPicker(
          title: "Medical License / Certificate",
          subtitle: "Verified registration certificate",
          file: certificateImage,
          onPick: () => _pickFile((f) => setState(() => certificateImage = f)),
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildInfoPanel(Color primaryColor) {
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
            Icon(Icons.privacy_tip_outlined, color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              "Credential Check",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your information is stored securely. Certification review typically takes 24 hours.",
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildInfoItem(Icons.verified_outlined, "Verified ID"),
            _buildInfoItem(Icons.verified_outlined, "License Valid"),
            _buildInfoItem(Icons.verified_outlined, "Hospital Sync"),
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
          Icon(icon, size: 16, color: const Color(0xFF0D9488)),
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
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (v) => v!.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Clinical Specialty", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedDepartment,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.medical_information_outlined, size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => selectedDepartment = v!),
        ),
      ],
    );
  }

  Widget _buildHospitalSelect(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Affiliated Hospital", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
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
                hintText: "Select Facility",
                prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
        ),
      ],
    );
  }

  Widget _buildDocPicker({
    required String title,
    required String subtitle,
    required PlatformFile? file,
    required VoidCallback onPick,
    required Color primaryColor,
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
                    child: Icon(Icons.edit, size: 14, color: primaryColor),
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
                border: Border.all(color: primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_rounded, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text("Upload", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 56,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isSubmitting
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Submit Application", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color primaryColor;

  const _SectionCard({required this.title, required this.icon, required this.children, required this.primaryColor});

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
              Icon(icon, color: primaryColor, size: 24),
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
