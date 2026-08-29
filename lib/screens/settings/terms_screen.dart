// lib/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const Color primaryColor = Color(0xFF27AE60);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE2E8F0);

  final String _effectiveDate = 'July 15, 2025';
  final String _contactEmail = 'mailto:legal@expenso.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Effective Date Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Effective Date: $_effectiveDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionCard(
              icon: Icons.check_circle_rounded,
              title: 'Acceptance of Terms',
              content:
                  'By downloading, installing, or using Expenso ("the App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.description_rounded,
              title: 'Description of Service',
              content:
                  'Expenso is a personal and business finance management application that allows users to:\n\n• Track income and expenses.\n• Generate financial reports.\n• Plan monthly budgets.\n• Backup and restore financial data.\n• Export data as PDF documents.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.person_rounded,
              title: 'User Accounts',
              content:
                  '• You must provide accurate information when creating an account.\n• You are responsible for maintaining password confidentiality.\n• You are responsible for all activities under your account.\n• Notify us immediately of any unauthorized use.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.gavel_rounded,
              title: 'User Responsibilities',
              content:
                  '• Use the App in compliance with all applicable laws.\n• Do not use the App for any illegal purpose.\n• Do not attempt unauthorized access to other users\' data.\n• Keep your device and app updated for security.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.privacy_tip_rounded,
              title: 'Data & Privacy',
              content:
                  'Your use of the App is also governed by our Privacy Policy. We take data protection seriously and implement appropriate security measures including Firebase Authentication and encrypted data storage.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.copyright_rounded,
              title: 'Intellectual Property',
              content:
                  'The App, including its design, logo, code, and content, is owned by Expenso and protected by copyright laws. You may not copy, modify, or distribute any part of the App without permission.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.warning_rounded,
              title: 'Limitation of Liability',
              content:
                  'Expenso is provided "as is" without warranties. We are not liable for:\n\n• Financial losses or decisions made based on the App.\n• Data loss (though backup features are provided).\n• Service interruptions or technical issues.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.block_rounded,
              title: 'Termination',
              content:
                  'We reserve the right to suspend or terminate your account if you violate these terms. You may stop using the App at any time and delete your data through Settings.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.change_history_rounded,
              title: 'Changes to Terms',
              content:
                  'We may modify these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms. Significant changes will be notified in-app.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.balance_rounded,
              title: 'Governing Law',
              content:
                  'These terms are governed by the laws of India. Any disputes shall be resolved in the appropriate courts of jurisdiction.',
            ),
            const SizedBox(height: 24),

            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.contact_mail_rounded,
                    size: 40,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For questions about these Terms:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _launchUrl(_contactEmail),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email Us',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'saktechnosolution@gmail.com',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Agreement Footer
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'By using Expenso, you acknowledge that you have read and agree to these Terms of Service.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: dividerColor),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw 'Could not launch $url';
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open link'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
