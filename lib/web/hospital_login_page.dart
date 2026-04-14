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
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    
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
          throw "Unauthorized access. This portal is for hospital accounts only.";
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
          SnackBar(
            content: const Text(
              "Registration successful. Please login and complete your hospital profile.",
            ),
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        setState(() => isLogin = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0891B2); // Cyan/Teal

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side: Login Form
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(60),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: primaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            isLogin ? "Hospital Portal" : "Join Network",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLogin 
                              ? "Access your hospital management dashboard" 
                              : "Register your facility to start managing records",
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Email Field
                          _buildTextField(
                            controller: emailController,
                            label: "Administrative Email",
                            icon: Icons.alternate_email_rounded,
                            hint: "admin@hospital.com",
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 24),
                          
                          // Password Field
                          _buildTextField(
                            controller: passwordController,
                            label: "Secure Password",
                            icon: Icons.lock_outline_rounded,
                            hint: "••••••••",
                            obscureText: _obscurePassword,
                            validator: (v) => v!.length < 6 ? "Too short" : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: loading ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    isLogin ? "Sign In" : "Create Account",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Toggle
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => isLogin = !isLogin),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                  children: [
                                    TextSpan(text: isLogin ? "New to the platform? " : "Already have an account? "),
                                    TextSpan(
                                      text: isLogin ? "Register now" : "Sign in",
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
          
          // Right side: Visual (for Web)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: primaryColor,
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=2053'),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Unified Healthcare\nManagement System",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Providing hospitals with the tools they need to deliver exceptional patient care through digital transformation.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
