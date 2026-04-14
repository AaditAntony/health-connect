import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookConsultationPage extends StatefulWidget {
  final String patientId;

  const BookConsultationPage({super.key, required this.patientId});

  @override
  State<BookConsultationPage> createState() => _BookConsultationPageState();
}

class _BookConsultationPageState extends State<BookConsultationPage> {
  late Razorpay _razorpay;

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

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _reasonController.dispose();
    super.dispose();
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

  // ================= PAYMENT HANDLERS =================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _completeBooking(paid: true, transactionId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    // Per user: always show success and mark as paid regardless of outcome
    await _completeBooking(paid: true, transactionId: "Manual-Approved");
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    await _completeBooking(paid: true, transactionId: "Wallet: ${response.walletName}");
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
      // 1. Fetch Hospital Fee
      final hospitalDoc = await FirebaseFirestore.instance.collection('accounts').doc(selectedHospitalId).get();
      final fee = hospitalDoc.exists ? (hospitalDoc.data()?['consultationFee'] ?? 0) : 0;

      if (fee <= 0) {
        // No fee, book directly
        await _completeBooking(paid: false);
        return;
      }

      // 2. Trigger Razorpay
      var options = {
        'key': 'rzp_test_1DP5mmOlF5G5ag', // Shared demo key from project
        'amount': fee * 100, // paise
        'name': 'Health Connect',
        'description': 'Consultation with $selectedDoctorName',
        'prefill': {
          'contact': patientData?['phone'] ?? '9999999999',
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

      // Create Appointment
      final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'targetId': selectedHospitalId,
        'targetName': selectedHospitalName,
        'requestedDoctorId': selectedDoctorId,
        'requestedDoctorName': selectedDoctorName,
        'department': selectedDepartment,
        'type': 'Consultation',
        'date': dateStr,
        'time': timeStr,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'paymentStatus': paid ? 'paid' : 'pending',
        'transactionId': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
        'patientMetadata': {
          'name': patientData?['name'] ?? "Unknown",
          'age': patientData?['age'] ?? "N/A",
          'phone': patientData?['phone'] ?? "N/A",
          'gender': patientData?['gender'] ?? "N/A",
        }
      });

      // If paid, create a payment record for the dashboard receipt
      if (paid) {
        await FirebaseFirestore.instance.collection('payments').add({
          'patientId': widget.patientId,
          'appointmentId': appointmentRef.id,
          'targetName': selectedHospitalName,
          'serviceType': 'Doctor Consultation',
          'doctorName': selectedDoctorName,
          'amount': (await FirebaseFirestore.instance.collection('accounts').doc(selectedHospitalId).get()).data()?['consultationFee'] ?? 0,
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
        title: const Text("Book Consultation", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("CHOOSE A SPECIALIST", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('accounts')
                  .where('role', isEqualTo: 'doctor')
                  .where('approved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Connection error"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No specialists available currently."));

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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  (data['doctorName'] ?? "D")[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['doctorName'] ?? "Dr. Specialist",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${data['department']} • ${data['experience']} Yrs Exp",
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          data['hospitalName'] ?? "Facility",
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 24)
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),

            const Text("CONSULTATION DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: "Briefly describe your health concern...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
              ),
            ),
            const SizedBox(height: 24),

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
            
            const SizedBox(height: 48),
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
                    : const Text("PROCEED TO CHECKOUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
