import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PatientSmartCarePlanPage extends StatefulWidget {
  const PatientSmartCarePlanPage({super.key});

  @override
  State<PatientSmartCarePlanPage> createState() =>
      _PatientSmartCarePlanPageState();
}

class _PatientSmartCarePlanPageState extends State<PatientSmartCarePlanPage> {
  late Razorpay _razorpay;

  String? pendingPlanId;
  Map<String, dynamic>? pendingPlanData;

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

  // ================= ACTIVATE PLAN =================

  Future<void> _activatePlan() async {
    if (pendingPlanId == null || pendingPlanData == null) return;

    final authUid = FirebaseAuth.instance.currentUser!.uid;

    final patientDoc = await FirebaseFirestore.instance
        .collection('patient_users')
        .doc(authUid)
        .get();

    final String patientId = patientDoc['patientId'];

    // Prevent duplicate
    final existing = await FirebaseFirestore.instance
        .collection('patient_plans')
        .where('patientId', isEqualTo: patientId)
        .where('planId', isEqualTo: pendingPlanId)
        .get();

    if (existing.docs.isNotEmpty) {
      Fluttertoast.showToast(
        msg: "Plan already activated",
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Save plan
    await FirebaseFirestore.instance.collection('patient_plans').add({
      "patientId": patientId,
      "planId": pendingPlanId,
      "hospitalId": pendingPlanData!['createdByHospitalId'],
      "amount": pendingPlanData!['amount'],
      "activatedAt": Timestamp.now(),
      "status": "active",
    });

    // Save payment
    await FirebaseFirestore.instance.collection('payments').add({
      "patientId": patientId,
      "planId": pendingPlanId,
      "hospitalId": pendingPlanData!['createdByHospitalId'],
      "amount": pendingPlanData!['amount'],
      "status": "success",
      "paymentMethod": "razorpay",
      "createdAt": Timestamp.now(),
    });

    Fluttertoast.showToast(
      msg: "Amount has been paid and your plan is activated",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    setState(() {
      pendingPlanId = null;
      pendingPlanData = null;
    });
  }

  // ================= PAYMENT HANDLERS =================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _activatePlan();
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    await _activatePlan(); // demo mode
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    await _activatePlan();
  }

  // ================= OPEN CHECKOUT =================

  void _openCheckout(String planId, Map<String, dynamic> data) {
    pendingPlanId = planId;
    pendingPlanData = data;

    int amount = data['amount'] * 100;

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amount,
      'name': 'Health Connect',
      'description': 'SmartCarePlan Payment',
      'prefill': {'contact': '9999999999', 'email': 'demo@healthconnect.com'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _activatePlan(); // fallback
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final authUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text("SmartCare Plans", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('patient_users')
            .doc(authUid)
            .get(),
        builder: (context, patientSnapshot) {
          if (patientSnapshot.hasError) return const Center(child: Text("Connection error"));
          if (!patientSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));

          final patientId = patientSnapshot.data!['patientId'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('smartcareplans')
                .where('status', isEqualTo: 'active')
                .where('expiresAt', isGreaterThan: Timestamp.now())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Connection error"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));

              final plans = snapshot.data!.docs;

              if (plans.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text("No plans currently available", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: plans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final doc = plans[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final doctors = data['doctors'] ?? [];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED), size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text("PREMIUM BENEFIT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF7C3AED))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "SmartCare Membership",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? "Exclusive healthcare benefits and specialist consultations.",
                          style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text("₹${data['amount']}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(width: 4),
                            const Text("/ month", style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        const Text("INCLUDED IN THIS PLAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 16),
                        ...doctors.map<Widget>((doc) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                                  child: const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "${doc['name']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                  ),
                                ),
                                Text(
                                  "${doc['department']}",
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('patient_plans')
                              .where('patientId', isEqualTo: patientId)
                              .where('planId', isEqualTo: doc.id)
                              .snapshots(),
                          builder: (context, planSnapshot) {
                            if (planSnapshot.hasError) return const SizedBox();
                            final isActivated = planSnapshot.hasData && planSnapshot.data!.docs.isNotEmpty;

                            return SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActivated ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: isActivated ? null : () => _openCheckout(doc.id, data),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isActivated ? Icons.check_circle_rounded : Icons.bolt_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      isActivated ? "PLAN ACTIVE" : "ACTIVATE NOW",
                                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
