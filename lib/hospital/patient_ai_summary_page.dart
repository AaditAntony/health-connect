import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../api_keys.dart';

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

    int visitCount = treatments.docs.length;

    try {
      if (ApiKeys.geminiApiKey == 'YOUR_API_KEY_HERE') {
        fullText = "Error: Please configure your Gemini API Key in lib/api_keys.dart to generate the AI Summary.";
        await Future.delayed(const Duration(seconds: 2));
      } else {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: ApiKeys.geminiApiKey,
        );
        
        // build the prompt
        String prompt = '''
You are a highly advanced AI medical assistant providing a report for $hospitalName. 
Please generate a comprehensive, professional, and clinical medical summary report for the patient.

Patient Profile:
Name: ${patient['name']}
Age: ${patient['age']}
Blood Group: ${patient['bloodGroup']}
Gender: ${patient['gender']}

Treatment History ($visitCount visits):
${treatments.docs.map((doc) => "- Diagnosis: ${doc['diagnosis']}, Treatment: ${doc['treatmentPlan']}").join('\n')}

Based on this data, provide a structured clinical medical summary report with the following sections (Do not use Markdown formatting like bold ** or headers # in your response, just plain text with line breaks as we are displaying it in a monospace code-like UI):
- CLINICAL OVERVIEW
- CLINICAL ANALYSIS (including healing suggestions and insights)
- RECOMMENDATIONS (practical recommendations for recovery)

Ensure that the tone is strictly professional. Do not invent any new medical conditions not implied by the treatment history.
''';

        final response = await model.generateContent([Content.text(prompt)]);
        
        fullText = """
AI-GENERATED MEDICAL SUMMARY
Generated on: ${DateTime.now().toLocal()}

------------------------------------------------------------

${response.text?.trim() ?? "Unable to generate AI summary."}

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
      }
    } catch (e) {
      print("AI Summary Error: $e");
      fullText = "An error occurred while generating the AI summary:\n\n$e";
    }

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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('accounts')
          .doc(widget.hospitalId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final hospitalData =
        snapshot.data!.data() as Map<String, dynamic>;

        final String? sealBase64 =
        hospitalData['sealSignBase64'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -------- SUMMARY TEXT --------
              Text(
                displayedText,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // -------- DIGITAL SIGNATURE AREA --------
              const Text(
                "Authorized & Digitally Verified By",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                hospitalData['hospitalName'] ?? "Hospital",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              // -------- SEAL IMAGE (BOTTOM LEFT STYLE) --------
              if (sealBase64 != null && sealBase64.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(sealBase64),
                      height: 80,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

}
