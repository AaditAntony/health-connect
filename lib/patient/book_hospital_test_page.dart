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
    Fluttertoast.showToast(msg: "Payment Failed. Booking as Pending Payment.", backgroundColor: Colors.orange);
    await _completeBooking(paid: false);
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
      Fluttertoast.showToast(msg: paid ? "Test Booked & Paid!" : "Test Appointment Requested!", backgroundColor: Colors.green);
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
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
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
                  : const Text("Request Test & Pay", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
