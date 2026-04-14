import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookHospitalTestPage extends StatefulWidget {
  final String patientId;

  const BookHospitalTestPage({super.key, required this.patientId});

  @override
  State<BookHospitalTestPage> createState() => _BookHospitalTestPageState();
}

class _BookHospitalTestPageState extends State<BookHospitalTestPage> {
  late Razorpay _razorpay;

  String? selectedHospitalId;
  String? selectedHospitalName;
  String testType = "Blood Test";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ================= PAYMENT HANDLERS =================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _completeBooking(paid: true, transactionId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    // Per user: always show success and mark as paid regardless
    await _completeBooking(paid: true, transactionId: "Manual-Approved");
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    await _completeBooking(paid: true, transactionId: "Wallet: ${response.walletName}");
  }

  void _submit() async {
    if (selectedHospitalId == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // 1. Fetch Hospital Fee
      final hospitalDoc = await FirebaseFirestore.instance.collection('accounts').doc(selectedHospitalId).get();
      final fee = hospitalDoc.exists ? (hospitalDoc.data()?['testFee'] ?? 0) : 0;

      if (fee <= 0) {
        await _completeBooking(paid: false);
        return;
      }

      // 2. Trigger Razorpay
      var options = {
        'key': 'rzp_test_1DP5mmOlF5G5ag',
        'amount': fee * 100,
        'name': 'Health Connect',
        'description': '$testType Booking at $selectedHospitalName',
        'prefill': {
          'contact': '9999999999',
          'email': 'patient@healthconnect.com'
        },
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error in booking flow: $e");
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _completeBooking({required bool paid, String? transactionId}) async {
    try {
      final dateStr = "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
      final timeStr = selectedTime!.format(context);

      final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'targetId': selectedHospitalId,
        'targetName': selectedHospitalName,
        'type': 'Test',
        'testType': testType,
        'date': dateStr,
        'time': timeStr,
        'status': 'pending',
        'paymentStatus': paid ? 'paid' : 'pending',
        'transactionId': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (paid) {
        await FirebaseFirestore.instance.collection('payments').add({
          'patientId': widget.patientId,
          'appointmentId': appointmentRef.id,
          'targetName': selectedHospitalName,
          'serviceType': 'Hospital Test',
          'testType': testType,
          'amount': (await FirebaseFirestore.instance.collection('accounts').doc(selectedHospitalId).get()).data()?['testFee'] ?? 0,
          'transactionId': transactionId,
          'status': 'success',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Fluttertoast.showToast(msg: "Appointment Registered Successfully!", backgroundColor: Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error finalizing booking: $e")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text("Book Diagnostic Test", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("TEST INFORMATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('accounts')
                  .where('role', isEqualTo: 'hospital')
                  .where('approved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Connection error"));
                if (!snapshot.hasData) return const CircularProgressIndicator(color: Color(0xFF7C3AED));
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text("No diagnostic centers available.");

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Hospital / Diagnostic Center",
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
                  ),
                  value: selectedHospitalId,
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Type of Test",
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
              ),
              value: testType,
              items: ["Blood Test", "X-Ray", "MRI Scan", "CT Scan", "General Checkup"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => testType = val);
              },
            ),

            const SizedBox(height: 32),

            const Text("SCHEDULE PREFERENCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final val = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (val != null) setState(() => selectedDate = val);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF7C3AED), size: 20),
                          const SizedBox(height: 8),
                          Text(
                            selectedDate == null
                                ? "Select Date"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final val = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 10, minute: 0),
                      );
                      if (val != null) setState(() => selectedTime = val);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Color(0xFF7C3AED), size: 20),
                          const SizedBox(height: 8),
                          Text(
                            selectedTime == null ? "Select Time" : selectedTime!.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRM & PAY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
