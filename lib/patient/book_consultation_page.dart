import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookConsultationPage extends StatefulWidget {
  final String patientId;

  const BookConsultationPage({super.key, required this.patientId});

  @override
  State<BookConsultationPage> createState() => _BookConsultationPageState();
}

class _BookConsultationPageState extends State<BookConsultationPage> {
  String? selectedDoctorId;
  String? selectedDoctorName;
  String? selectedHospitalId;
  String? selectedHospitalName;
  String? selectedDepartment;
  
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController _reasonController = TextEditingController();
  
  bool isSubmitting = false;
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();
      if (doc.exists) {
        setState(() {
          patientData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Error loading patient data: $e");
    }
  }

  void _submit() async {
    if (selectedDoctorId == null || selectedDate == null || selectedTime == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and provide a reason")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final dateStr = "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
      final timeStr = selectedTime!.format(context);

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId, // The app-wide patient ID
        'targetId': selectedHospitalId, // Targeting the Hospital
        'targetName': selectedHospitalName,
        'requestedDoctorId': selectedDoctorId,
        'requestedDoctorName': selectedDoctorName,
        'department': selectedDepartment,
        'type': 'Consultation',
        'date': dateStr,
        'time': timeStr,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'patientMetadata': {
          'name': patientData?['name'] ?? "Unknown",
          'age': patientData?['age'] ?? "N/A",
          'phone': patientData?['phone'] ?? "N/A",
          'gender': patientData?['gender'] ?? "N/A",
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment Requested Sent to Hospital!")),
      );
      Navigator.pop(context);
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
        title: const Text("Book Consultation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select a Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('accounts')
                  .where('role', isEqualTo: 'doctor')
                  .where('approved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text("No doctors available.");

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final isSelected = selectedDoctorId == docId;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDoctorId = docId;
                          selectedDoctorName = data['doctorName'] ?? data['name'] ?? "Unknown";
                          selectedHospitalId = data['hospitalId'];
                          selectedHospitalName = data['hospitalName'];
                          selectedDepartment = data['department'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF7C3AED).withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFFEDE9FE),
                              child: Text(
                                (data['doctorName'] ?? "D")[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['doctorName'] ?? "Dr. Unknown",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${data['department']} | ${data['experience']} Years Exp",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.business, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          data['hospitalName'] ?? "General Hospital",
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF7C3AED))
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            const Text("Reason for Consultation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Explain your health issue or specify if it is an emergency...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text("Select Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                    label: Text(selectedDate == null
                        ? "Pick Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                    onPressed: () async {
                      final val = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (val != null) setState(() => selectedDate = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.access_time, color: Color(0xFF7C3AED)),
                    label: Text(selectedTime == null ? "Pick Time" : selectedTime!.format(context)),
                    onPressed: () async {
                      final val = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 10, minute: 0),
                      );
                      if (val != null) setState(() => selectedTime = val);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Request Appointment", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
