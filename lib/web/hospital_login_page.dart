import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../hospital/hospital_dashboard.dart';
import '../hospital/hospital_profile_page.dart';
import '../hospital/hospital_verification_page.dart';


class HospitalLoginPage extends StatefulWidget {
  const HospitalLoginPage({super.key});

  @override
  State<HospitalLoginPage> createState() => _HospitalLoginPageState();
}

class _HospitalLoginPageState extends State<HospitalLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    try {
      UserCredential cred;

      if (isLogin) {
        // ---------- LOGIN ----------
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final doc = await FirebaseFirestore.instance
            .collection('accounts')
            .doc(cred.user!.uid)
            .get();

        if (!doc.exists || doc['role'] != 'hospital') {
          await FirebaseAuth.instance.signOut();
          throw "Not a hospital account";
        }

        final data = doc.data() as Map<String, dynamic>;

        // ---------- ROUTING ----------
        if (data['profileSubmitted'] != true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HospitalProfilePage(),
            ),
          );
        } else if (data['approved'] != true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HospitalVerificationPage(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HospitalDashboard(),
            ),
          );
        }
      } else {
        // ---------- REGISTER ----------
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(cred.user!.uid)
            .set({
          "email": emailController.text.trim(),
          "role": "hospital",
          "approved": false,
          "profileSubmitted": false,
        });

        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration successful. Please login and complete your hospital profile.",
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
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- ICON ----------
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Color(0xFF7C3AED),
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------- TITLE ----------
                  Text(
                    isLogin ? "Hospital Login" : "Hospital Registration",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isLogin
                        ? "Login to manage patient records"
                        : "Register your hospital for admin approval",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: Text(
                        loading
                            ? "Please wait..."
                            : isLogin
                            ? "Login"
                            : "Register",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      setState(() => isLogin = !isLogin);
                    },
                    child: Text(
                      isLogin
                          ? "No account? Register Hospital"
                          : "Already registered? Login",
                      style: const TextStyle(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
