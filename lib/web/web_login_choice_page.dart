import 'package:flutter/material.dart';
import 'admin_login_page.dart';
import 'hospital_login_page.dart';

class WebLoginChoicePage extends StatelessWidget {
  const WebLoginChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLoginPage(),
                        ),
                      );
                    },
                    child: const Text("Login as Admin"),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalLoginPage(),
                        ),
                      );
                    },
                    child: const Text("Login as Hospital"),
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
