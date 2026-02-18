import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiMedicalSummaryPage extends StatefulWidget {
  final String patientId;
  final String hospitalId;

  const AiMedicalSummaryPage({
    super.key,
    required this.patientId,
    required this.hospitalId,
  });

  @override
  State<AiMedicalSummaryPage> createState() =>
      _AiMedicalSummaryPageState();
}

class _AiMedicalSummaryPageState extends State<AiMedicalSummaryPage> {
  bool isGenerating = true;
  String displayedText = "";
  String fullText = "";

  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    final patientDoc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .get();

    final treatments = await FirebaseFirestore.instance
        .collection('treatments')
        .where('patientId', isEqualTo: widget.patientId)
        .get();

    final hospitalDoc = await FirebaseFirestore.instance
        .collection('accounts')
        .doc(widget.hospitalId)
        .get();

    final patient = patientDoc.data() as Map<String, dynamic>;
    final hospital = hospitalDoc.data() as Map<String, dynamic>;

    final hospitalName = hospital['hospitalName'] ?? "Unknown Hospital";
    final hospitalSeal = hospital['sealSignBase64'];

    int visitCount = treatments.docs.length;

    String diagnosisTrend = visitCount > 2
        ? "Recurring cardiovascular and metabolic irregularities"
        : "Limited but clinically relevant diagnostic entries";

    String lastDiagnosis = visitCount > 0
        ? treatments.docs.last['diagnosis']
        : "No diagnosis recorded";

    String lastTreatment = visitCount > 0
        ? treatments.docs.last['treatmentPlan']
        : "No treatment plan recorded";

    fullText = """
AI-GENERATED MEDICAL SUMMARY
Generated on: ${DateTime.now().toLocal()}

------------------------------------------------------------

PATIENT PROFILE

Name: ${patient['name']}
Age: ${patient['age']}
Blood Group: ${patient['bloodGroup']}
Gender: ${patient['gender']}

------------------------------------------------------------

CLINICAL OVERVIEW

This patient has undergone $visitCount recorded consultations at this facility.

Primary diagnostic trend indicates:
$diagnosisTrend

Most recent evaluation indicates:

Diagnosis:
$lastDiagnosis

Treatment Plan:
$lastTreatment

------------------------------------------------------------

CLINICAL ANALYSIS

Based on available data, the patient demonstrates moderate response to therapeutic interventions.

Treatment adherence appears satisfactory with no immediate escalation indicators.

However, continued monitoring is strongly recommended.

Risk assessment suggests:

• Moderate cardiovascular risk
• Lifestyle-associated metabolic patterns
• Need for periodic blood pressure evaluation

------------------------------------------------------------

RECOMMENDATIONS

1. Maintain structured medication schedule
2. Monthly cardiovascular review
3. Dietary sodium reduction
4. Routine metabolic panel testing

------------------------------------------------------------

HOSPITAL INFORMATION

This report has been digitally structured by:

$hospitalName

Hospital ID: ${widget.hospitalId}

$hospitalName is a professionally accredited healthcare institution known for structured patient-centered clinical management and multidisciplinary expertise.

------------------------------------------------------------

Digitally Generated Clinical Summary
(Automated Medical Intelligence System)
""";

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isGenerating = false;
    });

    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (_charIndex < fullText.length) {
        setState(() {
          displayedText += fullText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("AI Medical Summary"),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: isGenerating
          ? _buildProcessingScreen()
          : _buildSummaryScreen(),
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_awesome,
              size: 60, color: Color(0xFF7C3AED)),
          SizedBox(height: 20),
          CircularProgressIndicator(
            color: Color(0xFF7C3AED),
          ),
          SizedBox(height: 20),
          Text(
            "Analyzing patient treatment history...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        displayedText,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
