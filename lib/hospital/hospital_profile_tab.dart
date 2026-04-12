import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HospitalProfileTab extends StatefulWidget {
  const HospitalProfileTab({super.key});

  @override
  State<HospitalProfileTab> createState() => _HospitalProfileTabState();
}

class _HospitalProfileTabState extends State<HospitalProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _yearController;
  String? _district;

  final List<String> _districts = [
    "Ernakulam", "Thrissur", "Kozhikode", "Trivandrum", "Palakkad", "Kannur"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _yearController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('accounts').doc(uid).update({
      "hospitalName": _nameController.text.trim(),
      "address": _addressController.text.trim(),
      "district": _district,
      "establishedYear": _yearController.text.trim(),
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
          _nameController.text = data['hospitalName'] ?? "";
          _addressController.text = data['address'] ?? "";
          _yearController.text = data['establishedYear'] ?? "";
          _district = data['district'];
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(data),
              const SizedBox(height: 32),
              _buildProfileForm(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final String base64Image = data['profileImageBase64'] ?? "";
    final bool approved = data['approved'] ?? false;

    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            image: base64Image.isNotEmpty
                ? DecorationImage(image: MemoryImage(base64Decode(base64Image)), fit: BoxFit.cover)
                : null,
          ),
          child: base64Image.isEmpty ? const Icon(Icons.business, size: 40, color: Colors.grey) : null,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['hospitalName'] ?? "Unnamed Hospital",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(approved ? Icons.verified : Icons.hourglass_empty, 
                       color: approved ? Colors.green : Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    approved ? "Verified Institution" : "Verification Pending",
                    style: TextStyle(color: approved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() => _isEditing = !_isEditing),
          icon: Icon(_isEditing ? Icons.close : Icons.edit),
          label: Text(_isEditing ? "Cancel" : "Edit Profile"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEditing ? Colors.red : const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Basic Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField(_nameController, "Hospital Display Name", "e.g. City General Hospital"),
            const SizedBox(height: 16),
            _buildField(_addressController, "Full Physical Address", "Street, Area, PIN"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDistrictDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildField(_yearController, "Established Year", "e.g. 1995", isNum: true)),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Updated Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          enabled: _isEditing,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: _isEditing ? const BorderSide(color: Color(0xFF7C3AED)) : BorderSide.none),
          ),
          validator: (v) => v!.isEmpty ? "This field is required" : null,
        ),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("District", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _district,
          onChanged: _isEditing ? (v) => setState(() => _district = v) : null,
          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: _isEditing ? const BorderSide(color: Color(0xFF7C3AED)) : BorderSide.none),
          ),
        ),
      ],
    );
  }
}
