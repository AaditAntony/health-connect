import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'patient_link_page.dart';
import 'patient_dashboard.dart';

class PatientAuthPage extends StatefulWidget {
  const PatientAuthPage({super.key});

  @override
  State<PatientAuthPage> createState() => _PatientAuthPageState();
}

class _PatientAuthPageState extends State<PatientAuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    try {
      if (isLogin) {
        // ---------- LOGIN ----------
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final doc = await FirebaseFirestore.instance
            .collection('patient_users')
            .doc(cred.user!.uid)
            .get();

        if (!doc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientLinkPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientDashboard()),
          );
        }
      } else {
        // ---------- REGISTER ----------
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // IMPORTANT: sign out after register
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration successful. Please login to continue.",
            ),
          ),
        );

        setState(() => isLogin = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 400,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // -------- ICON --------
                      Container(
                        alignment: Alignment.center,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 36,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // -------- TITLE --------
                      Text(
                        isLogin ? "Patient Login" : "Patient Registration",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // -------- SUBTITLE --------
                      Text(
                        isLogin
                            ? "Access your medical records securely"
                            : "Create an account to access your medical history",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // -------- EMAIL --------
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // -------- PASSWORD --------
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // -------- BUTTON --------
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            loading
                                ? "Please wait..."
                                : isLogin
                                ? "Login"
                                : "Register",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------- TOGGLE --------
                      TextButton(
                        onPressed: () {
                          setState(() => isLogin = !isLogin);
                        },
                        child: Text(
                          isLogin
                              ? "Don’t have an account? Register"
                              : "Already have an account? Login",
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
