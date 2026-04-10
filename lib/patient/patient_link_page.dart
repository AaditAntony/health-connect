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
        if (phoneController.text.trim().isEmpty) throw "Please enter phone number";
        final query = await FirebaseFirestore.instance
            .collection('patients')
            .where('phone', isEqualTo: phoneController.text.trim())
            .get();
        if (query.docs.isEmpty) throw "No record found with this phone number. Please register as a new patient.";
        if (query.docs.length > 1) throw "Multiple records found. Try linking by Patient ID instead.";
        patientDoc = query.docs.first;
      }

      if (method == LinkMethod.patientId) {
        if (patientIdController.text.trim().isEmpty) throw "Please enter Patient ID";
        final doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientIdController.text.trim())
            .get();
        if (!doc.exists) throw "Invalid Patient ID. Check your hospital bill and try again.";
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
          context, MaterialPageRoute(builder: (_) => const PatientDashboard()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
          const SnackBar(content: Text("Please fill all required fields and select a hospital.")));
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
      await FirebaseFirestore.instance.collection('patient_registration_requests').doc(authUid).set({
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
            "Your registration request has been sent to the hospital. You will be able to access your dashboard once the hospital approves your record."),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================ BUILD ================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4C1D95),
        title: const Text(
          "Set Up Your Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7C3AED),
          tabs: const [
            Tab(icon: Icon(Icons.link), text: "Link Existing"),
            Tab(icon: Icon(Icons.person_add), text: "New Patient"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLinkTab(),
          _buildRegisterTab(),
        ],
      ),
    );
  }

  // ---- Link Existing Tab ----

  Widget _buildLinkTab() {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 4,
            shadowColor: const Color(0xFF7C3AED).withOpacity(0.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Link your hospital record",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C1D95))),
                  const SizedBox(height: 6),
                  const Text(
                      "If a hospital has already registered your record, link it here using your phone number or Patient ID.",
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: const Color(0xFFDDD6FE))),
                    child: Column(
                      children: [
                        RadioListTile<LinkMethod>(
                          value: LinkMethod.phone,
                          groupValue: method,
                          activeColor: const Color(0xFF7C3AED),
                          title: const Text("Use Phone Number"),
                          onChanged: (v) =>
                              setState(() => method = v!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<LinkMethod>(
                          value: LinkMethod.patientId,
                          groupValue: method,
                          activeColor: const Color(0xFF7C3AED),
                          title: const Text("Use Patient ID (from bill)"),
                          onChanged: (v) =>
                              setState(() => method = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (method == LinkMethod.phone)
                    _inputField(phoneController, "Phone Number",
                        keyboardType: TextInputType.phone),
                  if (method == LinkMethod.patientId)
                    _inputField(patientIdController, "Patient ID",
                        hint: "e.g. AbC123Xyz"),
                  const SizedBox(height: 26),
                  _actionButton(
                    label: loadingLink ? "Linking..." : "Link Record",
                    onPressed: loadingLink ? null : linkPatient,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- New Registration Tab ----

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 4,
            shadowColor: const Color(0xFF7C3AED).withOpacity(0.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Register as New Patient",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C1D95))),
                  const SizedBox(height: 6),
                  const Text(
                      "Your details will be sent to the chosen hospital for approval. Once confirmed, you can access your dashboard.",
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 22),
                  _inputField(nameRegController, "Full Name",
                      icon: Icons.person_outline),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(ageRegController, "Age",
                            keyboardType: TextInputType.number,
                            icon: Icons.cake_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: bloodGroupReg,
                          decoration: InputDecoration(
                            labelText: "Blood",
                            filled: true,
                            fillColor: const Color(0xFFFDFBFF),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          items: ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]
                              .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                              .toList(),
                          onChanged: (v) => setState(() => bloodGroupReg = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _inputField(phoneRegController, "Phone Number",
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_outlined),
                  const SizedBox(height: 14),
                  _inputField(emailRegController, "Email Address (Optional)",
                      icon: Icons.email_outlined),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: genderReg,
                    decoration: InputDecoration(
                      labelText: "Gender",
                      filled: true,
                      fillColor: const Color(0xFFFDFBFF),
                      prefixIcon: const Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (v) => setState(() => genderReg = v!),
                  ),
                  const SizedBox(height: 18),
                  const Text("Select Hospital for Registration",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
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
                          hintText: "Choose Hospital",
                          filled: true,
                          fillColor: const Color(0xFFFDFBFF),
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        items: hospitals.map((h) {
                          final d = h.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                              value: h.id, child: Text(d['hospitalName'] ?? "Unnamed"));
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
                  const SizedBox(height: 26),
                  _actionButton(
                    label: loadingReg ? "Requesting..." : "Submit Registration",
                    onPressed: loadingReg ? null : registerNewPatient,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Shared helpers ----

  Widget _inputField(TextEditingController ctrl, String label,
      {String? hint,
      TextInputType? keyboardType,
      IconData? icon}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFDFBFF),
        prefixIcon: icon != null ? Icon(icon) : null,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
      ),
    );
  }

  Widget _actionButton(
      {required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
    );
  }
}