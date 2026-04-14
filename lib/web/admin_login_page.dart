import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
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
        // -------- LOGIN --------
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // -------- REGISTER ADMIN (TEMP ACCOUNT) --------
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(cred.user!.uid)
            .set({
          "email": emailController.text.trim(),
          "role": "hospital", // admin approval is manual
          "approved": false,
        });
      }

      final doc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists ||
          doc['role'] != 'admin' ||
          doc['approved'] != true) {
        await FirebaseAuth.instance.signOut();
        throw "Admin access pending approval. Please contact system administrator.";
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
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
    const primaryColor = Color(0xFF4F46E5); // Command Indigo

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left side: Branding/Visual (for Web)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B4B),
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&q=80&w=2070'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_rounded, color: primaryColor, size: 80),
                    const SizedBox(height: 32),
                    const Text(
                      "Health Connect\nAdmin Console.",
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
                      "Secure infrastructure management for the modern healthcare ecosystem.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right side: Login Form
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
                            isLogin ? "Sign In" : "Register Admin",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLogin 
                              ? "Enter your administrative credentials" 
                              : "Create a new admin request",
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Email Field
                          _buildTextField(
                            controller: emailController,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            hint: "admin@healthconnect.com",
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 24),
                          
                          // Password Field
                          _buildTextField(
                            controller: passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
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
                                    isLogin ? "Log In" : "Register Now",
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
                                    TextSpan(text: isLogin ? "Don't have an account? " : "Already have an account? "),
                                    TextSpan(
                                      text: isLogin ? "Register Admin" : "Sign In",
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
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
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

