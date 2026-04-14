import 'package:flutter/material.dart';
import 'package:health_connect/doctor/doctor_auth_page.dart';
import 'admin_login_page.dart';
import 'hospital_login_page.dart';

class WebLoginChoicePage extends StatefulWidget {
  const WebLoginChoicePage({super.key});

  @override
  State<WebLoginChoicePage> createState() => _WebLoginChoicePageState();
}

class _WebLoginChoicePageState extends State<WebLoginChoicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D9488).withOpacity(0.05),
                ),
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Identity
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 48,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Health Connect",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "The Future of Healthcare Management",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Role Cards Container
                    Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _RoleCard(
                            title: "Medical Staff",
                            subtitle: "Doctor Dashboard",
                            description: "Manage appointments, patient histories, and clinical reports.",
                            icon: Icons.medical_services_outlined,
                            baseColor: const Color(0xFF6366F1), // Indigo
                            page: const DoctorAuthPage(),
                          ),
                          _RoleCard(
                            title: "Hospital Admin",
                            subtitle: "Facility Control",
                            description: "Manage hospital data, staff registration, and facility resources.",
                            icon: Icons.local_hospital_outlined,
                            baseColor: const Color(0xFF0D9488), // Teal
                            page: const HospitalLoginPage(),
                          ),
                          _RoleCard(
                            title: "System Admin",
                            subtitle: "Platform Control",
                            description: "Global system configuration, user management, and auditing.",
                            icon: Icons.admin_panel_settings_outlined,
                            baseColor: const Color(0xFF4F46E5), // Command Indigo
                            page: const AdminLoginPage(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Footer
                    Text(
                      "© 2024 Health Connect. Premium Secure Portal.",
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color baseColor;
  final Widget page;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.baseColor,
    required this.page,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => widget.page),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered ? widget.baseColor : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered 
                  ? widget.baseColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
                blurRadius: isHovered ? 40 : 20,
                offset: isHovered ? const Offset(0, 20) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.baseColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.subtitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.baseColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    "Enter Portal",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isHovered ? widget.baseColor : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.only(left: isHovered ? 8 : 0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: isHovered ? widget.baseColor : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
