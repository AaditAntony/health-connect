import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookHospitalTestPage extends StatefulWidget {
  final String patientId;

  const BookHospitalTestPage({super.key, required this.patientId});

  @override
  State<BookHospitalTestPage> createState() => _BookHospitalTestPageState();
}

class _BookHospitalTestPageState extends State<BookHospitalTestPage> {
  String? selectedHospitalId;
  String? selectedHospitalName;
  String testType = "Blood Test";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isSubmitting = false;

  void _submit() async {
    if (selectedHospitalId == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final dateStr = "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
      final timeStr = selectedTime!.format(context);

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'targetId': selectedHospitalId,
        'targetName': selectedHospitalName,
        'type': 'Test',
        'testType': testType,
        'date': dateStr,
        'time': timeStr,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Test Appointment Requested Successfully!")),
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
        title: const Text("Book Hospital Test"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Select a Hospital", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('accounts')
                  .where('role', isEqualTo: 'hospital')
                  .where('approved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error: ${snapshot.error}");
          return Center(child: Text("Error: \n${snapshot.error}", textAlign: TextAlign.center));
        }
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text("No hospitals available.");

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  value: selectedHospitalId,
                  hint: const Text("Choose Hospital"),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['hospitalName'] ?? "Unknown Hospital";
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedHospitalId = val;
                      final selectedDoc = docs.firstWhere((doc) => doc.id == val);
                      final data = selectedDoc.data() as Map<String, dynamic>;
                      selectedHospitalName = data['hospitalName'] ?? "Unknown Hospital";
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            const Text("Select Test Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: testType,
              items: ["Blood Test", "X-Ray", "MRI Scan", "CT Scan", "General Checkup"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => testType = val);
              },
            ),

            const SizedBox(height: 24),

            const Text("Select Date & Time", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
            
            const Spacer(),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Request Test", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
