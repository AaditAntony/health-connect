import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/responsive.dart';

class DoctorDetailPage extends StatelessWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Doctor Verification"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: ResponsiveWrapper(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('accounts').doc(doctorId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.data() == null) return const Center(child: CircularProgressIndicator());

            final data = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(data),
                  const SizedBox(height: 32),
                  _buildDocumentSection(context, data),
                  const SizedBox(height: 48),
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImage(data['profileImageBase64']),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['doctorName'] ?? "Unnamed Doctor", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.medical_services, data['department'] ?? "N/A", color: const Color(0xFF4F46E5)),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.business, data['hospitalName'] ?? "No Hospital Assigned"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildBadge("${data['age'] ?? '??'} Years Old"),
                    _buildBadge("${data['experience'] ?? '0'} Years Exp"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? b64) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: b64 != null
          ? Image.memory(base64Decode(b64), width: 100, height: 120, fit: BoxFit.cover)
          : Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.grey.shade600, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildDocumentSection(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Medical Credentials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        _buildDocCard(context, "Registration Certificate", data['certificateBase64']),
      ],
    );
  }

  Widget _buildDocCard(BuildContext context, String title, String? b64) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              if (b64 != null) const Icon(Icons.verified_user, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (b64 != null)
            GestureDetector(
              onTap: () => _viewImageFull(context, b64, title),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(base64Decode(b64), width: double.infinity, height: 250, fit: BoxFit.cover),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Tap to view full screen", style: TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  ],
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text("Document not uploaded", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
    );
  }

  void _viewImageFull(BuildContext context, String b64, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(title, style: const TextStyle(color: Colors.white)),
              leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(child: InteractiveViewer(child: Image.memory(base64Decode(b64)))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirmAction(context, "Reject", "Reject and delete this registration?", const Color(0xFFE11D48), () async {
              await FirebaseFirestore.instance.collection('accounts').doc(doctorId).delete();
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE11D48),
              side: const BorderSide(color: Color(0xFFE11D48)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Reject applicant", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirmAction(context, "Approve", "Grant platform access to this doctor?", const Color(0xFF4F46E5), () async {
              await FirebaseFirestore.instance.collection('accounts').doc(doctorId).update({"approved": true});
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text("Approve Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _confirmAction(BuildContext pageContext, String title, String msg, Color color, Future<void> Function() action) {
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await action();
              if (pageContext.mounted) Navigator.pop(pageContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(title),
          ),
        ],
      ),
    );
  }
}
