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
    // Per user: "if the payment is success or failure make sure the appointment is success"
    Fluttertoast.showToast(msg: "Payment Failed. Booking as Pending Payment.", backgroundColor: Colors.orange);
    await _completeBooking(paid: false);
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
      Fluttertoast.showToast(msg: paid ? "Appointment Booked & Paid!" : "Appointment Requested Successfully!", backgroundColor: Colors.green);
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
                  : const Text("Request Appointment & Pay", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
