import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_connect/patient/patient_dashboard.dart';

enum LinkMethod { phone, patientId }

class PatientLinkPage extends StatefulWidget {
  const PatientLinkPage({super.key});

  @override
  State<PatientLinkPage> createState() => _PatientLinkPageState();
}

class _PatientLinkPageState extends State<PatientLinkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Link Tab ---
  final phoneController = TextEditingController();
  final patientIdController = TextEditingController();
  LinkMethod method = LinkMethod.phone;
  bool loadingLink = false;

  // --- Register Tab ---
  final nameRegController = TextEditingController();
  final ageRegController = TextEditingController();
  final phoneRegController = TextEditingController();
  final emailRegController = TextEditingController();
  String? selectedHospitalId;
  String? selectedHospitalName;
  String genderReg = "Male";
  String bloodGroupReg = "O+";
  bool loadingReg = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================ LINK EXISTING ================

  Future<void> linkPatient() async {
    setState(() => loadingLink = true);
    final authUid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot? patientDoc;

    try {
      if (method == LinkMethod.phone) {
        if (phoneController.text.trim().isEmpty)
          throw "Please enter phone number";
        final query = await FirebaseFirestore.instance
            .collection('patients')
            .where('phone', isEqualTo: phoneController.text.trim())
            .get();
        if (query.docs.isEmpty)
          throw "No record found with this phone number. Please register as a new patient.";
        if (query.docs.length > 1)
          throw "Multiple records found. Try linking by Patient ID instead.";
        patientDoc = query.docs.first;
      }

      if (method == LinkMethod.patientId) {
        if (patientIdController.text.trim().isEmpty)
          throw "Please enter Patient ID";
        final doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientIdController.text.trim())
            .get();
        if (!doc.exists)
          throw "Invalid Patient ID. Check your hospital bill and try again.";
        patientDoc = doc;
      }

      await FirebaseFirestore.instance
          .collection('patient_users')
          .doc(authUid)
          .set({
            "authUid": authUid,
            "patientId": patientDoc!.id,
            "linkedAt": Timestamp.now(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medical record linked successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => loadingLink = false);
  }

  // ================ REGISTER NEW ================

  Future<void> registerNewPatient() async {
    if (nameRegController.text.trim().isEmpty ||
        ageRegController.text.trim().isEmpty ||
        phoneRegController.text.trim().isEmpty ||
        selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields and select a hospital.",
          ),
        ),
      );
      return;
    }
    setState(() => loadingReg = true);
    final authUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Check for duplicate requests or existing records
      final existing = await FirebaseFirestore.instance
          .collection('patients')
          .where('phone', isEqualTo: phoneRegController.text.trim())
          .get();
      if (existing.docs.isNotEmpty) {
        throw "A patient with this phone number already exists.\nPlease use the 'Link Existing Record' tab instead.";
      }

      // Submit registration request to chosen hospital
      await FirebaseFirestore.instance
          .collection('patient_registration_requests')
          .doc(authUid)
          .set({
            "authUid": authUid,
            "name": nameRegController.text.trim(),
            "age": ageRegController.text.trim(),
            "gender": genderReg,
            "bloodGroup": bloodGroupReg,
            "phone": phoneRegController.text.trim(),
            "email": emailRegController.text.trim(),
            "hospitalId": selectedHospitalId,
            "hospitalName": selectedHospitalName,
            "requestedAt": Timestamp.now(),
            "status": "pending",
          });

      if (!mounted) return;
      _showRegistrationPendingDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => loadingReg = false);
  }

  void _showRegistrationPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Registration Submitted"),
        content: const Text(
          "Your registration request has been sent to the hospital. You will be able to access your dashboard once the hospital approves your record.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================ BUILD ================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          "Complete Your Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Link Existing"),
            Tab(text: "Register New"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLinkTab(), _buildRegisterTab()],
      ),
    );
  }

  // ---- Link Existing Tab ----

  Widget _buildLinkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Access Your Records",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "If a hospital has already registered you, link your records here.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _methodButton(
                    label: "Phone",
                    isSelected: method == LinkMethod.phone,
                    onTap: () => setState(() => method = LinkMethod.phone),
                  ),
                ),
                Expanded(
                  child: _methodButton(
                    label: "Patient ID",
                    isSelected: method == LinkMethod.patientId,
                    onTap: () => setState(() => method = LinkMethod.patientId),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (method == LinkMethod.phone)
            _inputField(
              phoneController,
              "Phone Number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hint: "Enter registered number",
            ),
          if (method == LinkMethod.patientId)
            _inputField(
              patientIdController,
              "Patient ID",
              icon: Icons.tag,
              hint: "Check your hospital document",
            ),

          const SizedBox(height: 40),

          _actionButton(
            label: loadingLink ? "Verifying..." : "Link My Records",
            onPressed: loadingLink ? null : linkPatient,
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Need help? Contact your hospital administrator.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF7C3AED)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ---- New Registration Tab ----

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New Registration",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Register your details with your preferred hospital.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 32),

          _inputField(
            nameRegController,
            "Full Name",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _inputField(
                  ageRegController,
                  "Age",
                  keyboardType: TextInputType.number,
                  icon: Icons.cake_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dropdownField(
                  label: "Blood Group",
                  value: bloodGroupReg,
                  items: ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"],
                  onChanged: (v) => setState(() => bloodGroupReg = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _inputField(
            phoneRegController,
            "Phone Number",
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 20),

          _dropdownField(
            label: "Gender",
            value: genderReg,
            items: ["Male", "Female", "Other"],
            onChanged: (v) => setState(() => genderReg = v!),
          ),
          const SizedBox(height: 32),

          const Text(
            "Primary Hospital",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('accounts')
                .where('role', isEqualTo: 'hospital')
                .where('approved', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final hospitals = snapshot.data!.docs;
              return DropdownButtonFormField<String>(
                value: selectedHospitalId,
                decoration: InputDecoration(
                  hintText: "Choose a healthcare facility",
                  prefixIcon: const Icon(Icons.business_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: hospitals.map((h) {
                  final d = h.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: h.id,
                    child: Text(d['hospitalName'] ?? "Unnamed"),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedHospitalId = v;
                    final doc = hospitals.firstWhere((h) => h.id == v);
                    selectedHospitalName =
                        (doc.data() as Map<String, dynamic>)['hospitalName'];
                  });
                },
              );
            },
          ),
          const SizedBox(height: 40),

          _actionButton(
            label: loadingReg ? "Submitting..." : "Send Request",
            onPressed: loadingReg ? null : registerNewPatient,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---- Helpers ----

  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
