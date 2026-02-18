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

class _PatientSmartCarePlanPageState
    extends State<PatientSmartCarePlanPage> {
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

  // ================= PAYMENT HANDLERS =================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (pendingPlanId == null || pendingPlanData == null) return;

    final authUid = FirebaseAuth.instance.currentUser!.uid;

    final patientDoc = await FirebaseFirestore.instance
        .collection('patient_users')
        .doc(authUid)
        .get();

    final patientId = patientDoc['patientId'];

    await FirebaseFirestore.instance.collection('patient_plans').add({
      "patientId": patientId,
      "planId": pendingPlanId,
      "hospitalId": pendingPlanData!['createdByHospitalId'],
      "amount": pendingPlanData!['amount'],
      "activatedAt": Timestamp.now(),
      "status": "active",
    });

    Fluttertoast.showToast(msg: "Payment successful. Plan activated!");

    setState(() {
      pendingPlanId = null;
      pendingPlanData = null;
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment failed. Plan not activated.");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External wallet selected");
  }

  // ================= OPEN RAZORPAY =================

  void _openCheckout(String planId, Map<String, dynamic> data) async {
    pendingPlanId = planId;
    pendingPlanData = data;

    int amount = data['amount'] * 100; // convert to paisa

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amount,
      'name': 'Health Connect',
      'description': 'SmartCarePlan Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'prefill': {
        'contact': '9999999999',
        'email': 'test@razorpay.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("SmartCare Plans"),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('smartcareplans')
            .where('status', isEqualTo: 'active')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data!.docs;

          if (plans.isEmpty) {
            return const Center(
              child: Text("No plans available"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final doc = plans[index];
              final data = doc.data() as Map<String, dynamic>;
              final doctors = data['doctors'] ?? [];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          const Icon(Icons.workspace_premium,
                              color: Color(0xFF7C3AED)),
                          const SizedBox(width: 10),
                          const Text(
                            "SmartCarePlan",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "₹ ${data['amount']} / Month",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(data['description'] ?? ""),

                      const Divider(height: 24),

                      ...doctors.map<Widget>((doc) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18,
                                  color: Color(0xFF7C3AED)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${doc['name']} • ${doc['department']}",
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                          ),
                          onPressed: () =>
                              _openCheckout(doc.id, data),
                          child: const Text(
                            "Activate Plan",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
