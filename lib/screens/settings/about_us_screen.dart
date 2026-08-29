// lib/screen/Settings/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Color scheme matching your app
  static const Color primaryColor = Color.fromARGB(255, 42, 172, 131);
  static const Color accentColor = Color(0xFFD4AF37);
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // URLs - Replace with your actual links
  static const String companyWebsite = 'https://www.saktechnosolution.com';
  static const String companyInstagram =
      'https://instagram.com/sak.technosolution';
  static const String companyWhatsApp = 'https://wa.me/+919995258618';
  static const String companyEmail = 'saktechnosolution@gmail.com';

  static const String developerWebsite =
      'https://ahamedrameez.saktechnosolution.com';
  static const String developerInstagram = 'https://instagram.com/ramiiz.__';
  static const String developerWhatsApp = 'https://wa.me/+919995258618';
  static const String developerLinkedIn =
      'https://www.linkedin.com/in/ahamed-rameez-a2ab00283/';
  static const String developerGithub = 'https://github.com/AhamedRameez';

  // Launch URL function
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🏢 COMPANY SECTION
            _buildSection(
              icon: Icons.business_center_rounded,
              title: 'About Company',
              color: primaryColor,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Rectangular Logo from assets
                  Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/sak_logo.png',
                        width: 120,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, accentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'S',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '.A.K',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company Name
                  const Text(
                    'S.A.K Techno Solution',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Company Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Innovative Tech Solutions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔥 UPDATED: Company Description - Professional & No Background
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'S.A.K Techno Solution is a registered technology company specializing in custom Flutter application development. We serve a diverse range of clients, from Islamic organizations to businesses across various industries, delivering tailored, high-performance mobile solutions. Our commitment to quality, innovation, and customer satisfaction ensures that every project meets the highest standards of excellence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Social Links Row
                  _buildSocialLinks(
                    links: [
                      SocialLink(
                        icon: Icons.language_rounded,
                        color: Colors.blue,
                        label: 'Website',
                        url: companyWebsite,
                      ),
                      SocialLink(
                        icon: Icons.email_rounded,
                        color: Colors.red,
                        label: 'Email',
                        url: 'mailto:$companyEmail',
                      ),
                      SocialLink(
                        icon: Icons.camera_alt_rounded,
                        color: Colors.purple,
                        label: 'Instagram',
                        url: companyInstagram,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 👨‍💻 DEVELOPER SECTION
            _buildSection(
              icon: Icons.code_rounded,
              title: 'About Developer',
              color: accentColor,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Developer Avatar - Rectangular
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Developer Name
                  const Text(
                    'Ahamed Rameez',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Developer Role
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Founder & Developer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Developer Description
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Passionate Flutter developer with expertise in building beautiful and functional Flutter applications. Dedicated to creating seamless user experiences with clean code and innovative features.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Developer Social Links
                  _buildSocialLinks(
                    links: [
                      SocialLink(
                        icon: Icons.language_rounded,
                        color: Colors.blue,
                        label: 'Website',
                        url: developerWebsite,
                      ),
                      SocialLink(
                        icon: Icons.camera_alt_rounded,
                        color: Colors.purple,
                        label: 'Instagram',
                        url: developerInstagram,
                      ),
                      SocialLink(
                        icon: Icons.message_rounded,
                        color: Colors.green,
                        label: 'WhatsApp',
                        url: developerWhatsApp,
                      ),
                      SocialLink(
                        icon: Icons.business_center_rounded,
                        color: Colors.blue[700]!,
                        label: 'LinkedIn',
                        url: developerLinkedIn,
                      ),
                      SocialLink(
                        icon: Icons.code_rounded,
                        color: Colors.black,
                        label: 'GitHub',
                        url: developerGithub,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📱 APP INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  const Text(
                    'In Expenso',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.3',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year} S.A.K Techno Solution. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Section Builder - Removed background color
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // 🔥 REMOVED: color: cardColor (now transparent)
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: dividerColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // Social Links Builder
  Widget _buildSocialLinks({required List<SocialLink> links}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: links.map((link) {
        return InkWell(
          onTap: () => _launchUrl(link.url),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: link.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: link.color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(link.icon, size: 16, color: link.color),
                const SizedBox(width: 6),
                Text(
                  link.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: link.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Social Link Model
class SocialLink {
  final IconData icon;
  final Color color;
  final String label;
  final String url;

  SocialLink({
    required this.icon,
    required this.color,
    required this.label,
    required this.url,
  });
}
