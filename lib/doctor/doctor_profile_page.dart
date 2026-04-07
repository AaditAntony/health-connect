import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate() || selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a hospital")),
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
        'profileSubmitted': true,
        'approved': false, // Requires admin approval
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile submitted for Admin approval!")),
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
              const Text(
                "Professional Information",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please fill in your details to connect with your hospital.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name (e.g. Dr. John Doe)",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Age",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Exp (Years)",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: InputDecoration(
                  labelText: "Department",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.medical_services),
                ),
                items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => selectedDepartment = v!),
              ),
              const SizedBox(height: 20),

              const Text("Select Your Hospital", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('accounts')
                    .where('role', isEqualTo: 'hospital')
                    .where('approved', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  
                  final hospitals = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedHospitalId,
                    decoration: InputDecoration(
                      hintText: "Choose Hospital",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    items: hospitals.map((h) {
                      final data = h.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: h.id,
                        child: Text(data['hospitalName'] ?? "Unnamed"),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedHospitalId = v;
                        final selectedDoc = hospitals.firstWhere((doc) => doc.id == v);
                        final data = selectedDoc.data() as Map<String, dynamic>;
                        selectedHospitalName = data['hospitalName'];
                      });
                    },
                  );
                },
              ),
              
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: isSubmitting ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Profile",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
