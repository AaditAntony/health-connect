import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorProfileTab extends StatefulWidget {
  const DoctorProfileTab({super.key});

  @override
  State<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<DoctorProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _expController;
  late TextEditingController _ageController;
  String? _department;

  final List<String> _departments = [
    "General Medicine", "Cardiology", "Oncology", "Pediatrics", 
    "Neurology", "Orthopedics", "Dermatology", "Radiology"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _expController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('accounts').doc(uid).update({
      "doctorName": _nameController.text.trim(),
      "experience": int.parse(_expController.text.trim()),
      "age": int.parse(_ageController.text.trim()),
      "department": _department,
    });

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        if (!_isEditing) {
          _nameController.text = data['doctorName'] ?? "";
          _expController.text = (data['experience'] ?? 0).toString();
          _ageController.text = (data['age'] ?? 0).toString();
          _department = data['department'];
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(data),
              const SizedBox(height: 32),
              _buildDetailsForm(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> data) {
    final String base64Image = data['profileImageBase64'] ?? "";
    final bool approved = data['approved'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: base64Image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.memory(base64Decode(base64Image), fit: BoxFit.cover),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['doctorName'] ?? "Dr. Specialist",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      data['department'] ?? "Consultant",
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 8),
                    _buildStamp(approved),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStamp(bool approved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: approved ? Colors.greenAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: approved ? Colors.greenAccent : Colors.orangeAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(approved ? Icons.verified : Icons.hourglass_top, 
               color: approved ? Colors.greenAccent : Colors.orangeAccent, size: 12),
          const SizedBox(width: 6),
          Text(
            approved ? "VERIFIED PROVIDER" : "APPROVAL PENDING",
            style: TextStyle(
              color: approved ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            _buildField(_nameController, "Full Professional Name", Icons.person_outline),
            const SizedBox(height: 20),
            _buildDepartmentDropdown(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildField(_expController, "Experience (Yrs)", Icons.work_outline, isNum: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(_ageController, "Current Age", Icons.cake_outlined, isNum: true)),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          enabled: _isEditing,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
            filled: true,
            fillColor: _isEditing ? Colors.white : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isEditing ? const BorderSide(color: Color(0xFF7C3AED), width: 2) : BorderSide.none,
            ),
          ),
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Specialization / Department", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _department,
          onChanged: _isEditing ? (v) => setState(() => _department = v) : null,
          items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.medical_services_outlined, size: 18, color: Color(0xFF7C3AED)),
            filled: true,
            fillColor: _isEditing ? Colors.white : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isEditing ? const BorderSide(color: Color(0xFF7C3AED), width: 2) : BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
