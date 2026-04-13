import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/auth_wrapper.dart';

class DoctorAuthPage extends StatefulWidget {
  const DoctorAuthPage({super.key});

  @override
  State<DoctorAuthPage> createState() => _DoctorAuthPageState();
}

class _DoctorAuthPageState extends State<DoctorAuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    try {
      if (isLogin) {
        // ---------- LOGIN ----------
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      } else {
        // ---------- REGISTER ----------
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Save to 'accounts' collection
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(cred.user!.uid)
            .set({
          'email': emailController.text.trim(),
          'role': 'doctor',
          'approved': false,
          'profileSubmitted': false, // They might need a profile later
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful. Please wait for admin approval before logging in."),
          ),
        );
        setState(() => isLogin = true);
      }
    } catch (e) {
      if (!mounted) return;
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_information,
                            size: 36,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // -------- TITLE --------
                      Text(
                        isLogin ? "Doctor Login" : "Doctor Registration",
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
                            ? "Provide expert care to your patients"
                            : "Join our network of healthcare professionals",
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
                            backgroundColor: const Color(0xFF0D9488),
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
                              ? "New to the platform? Apply here"
                              : "Already have an account? Login",
                          style: const TextStyle(color: Color(0xFF0D9488)),
                        ),
                      ),
                      
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to role selection
                        },
                        child: const Text("Back to Role Selection",
                            style: TextStyle(color: Colors.grey)),
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
