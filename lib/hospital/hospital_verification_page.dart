import 'package:flutter/material.dart';
import '../core/responsive.dart';

class HospitalVerificationPage extends StatelessWidget {
  const HospitalVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification Pending")),
      body: ResponsiveWrapper(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                "Your details have been submitted",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "After admin verification,\nyou will be permitted.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
