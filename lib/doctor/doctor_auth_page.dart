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
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    
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
          'profileSubmitted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Registration successful. Please wait for admin approval before logging in."),
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() => isLogin = true);
      }
    } catch (e) {
      if (!mounted) return;
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
    const primaryColor = Color(0xFF0D9488); // Clinical Teal

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side: Branding/Visual (for Web)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF134E4A),
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=2048'),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_rounded, color: primaryColor, size: 80),
                    const SizedBox(height: 32),
                    const Text(
                      "Medical Excellence\nPowered by Technology.",
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
                      "Elevate your clinical practice with our unified healthcare management ecosystem.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right side: Auth Form
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
                          Text(
                            isLogin ? "Welcome Back" : "Join the Network",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLogin 
                              ? "Enter your clinical credentials" 
                              : "Register your professional profile",
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Email Field
                          _buildTextField(
                            controller: emailController,
                            label: "Professional Email",
                            icon: Icons.email_outlined,
                            hint: "dr.name@healthconnect.com",
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
                                    isLogin ? "Sign In" : "Register Profile",
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
                                    TextSpan(text: isLogin ? "Not registered? " : "Already have an account? "),
                                    TextSpan(
                                      text: isLogin ? "Apply Now" : "Sign In",
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
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Back to Role Selection", style: TextStyle(color: Color(0xFF94A3B8))),
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
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
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
