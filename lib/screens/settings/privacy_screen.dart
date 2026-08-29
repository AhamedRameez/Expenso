// lib/screens/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE2E8F0);

  final String _lastUpdated = 'July 15, 2025';
  final String _contactEmail = 'mailto:support@expenso.com';
  final String _privacyUrl = 'https://www.expenso.com/privacy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
            // Last Updated Badge
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
                    Icon(Icons.update_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Last Updated: $_lastUpdated',
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

            // Our Commitment
            _buildPolicyCard(
              icon: Icons.privacy_tip_rounded,
              title: 'Our Commitment to Privacy',
              content:
                  'Expenso is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your personal and financial information when you use our app.',
            ),
            const SizedBox(height: 16),

            // Information Collection
            _buildPolicyCard(
              icon: Icons.info_rounded,
              title: 'Information Collection and Use',
              content:
                  'We collect the following information to provide and improve our service:\n\n'
                  '• Personal Information: Name, email, phone number, and business details.\n'
                  '• Financial Data: Income records, expense transactions, and budget plans.\n'
                  '• Device Information: Device type, OS version, and app usage statistics.\n\n'
                  'All data is used solely for app functionality and user experience enhancement.',
            ),
            const SizedBox(height: 16),

            // Firebase Services
            _buildPolicyCard(
              icon: Icons.cloud_rounded,
              title: 'Firebase Services',
              content:
                  'This app uses Firebase services provided by Google to store and process data. Firebase may collect information in accordance with its privacy policy. We use Firebase for:\n\n'
                  '• Cloud Firestore (data storage)\n'
                  '• Firebase Authentication (user login)\n'
                  '• Firebase Security Rules (data protection)',
            ),
            const SizedBox(height: 16),

            // Data Storage
            _buildPolicyCard(
              icon: Icons.storage_rounded,
              title: 'Data Storage & Security',
              content:
                  'Your data is stored securely on Firebase Cloud Firestore with encryption at rest and in transit. We implement:\n\n'
                  '• Secure authentication via email/password.\n'
                  '• Encrypted data transmission (SSL/TLS).\n'
                  '• Access controls through Firebase Security Rules.\n'
                  '• Regular security updates and monitoring.',
            ),
            const SizedBox(height: 16),

            // Data Sharing
            _buildPolicyCard(
              icon: Icons.share_rounded,
              title: 'Data Sharing',
              content:
                  'We do NOT sell, trade, or rent your personal information to third parties. Your financial data is private and only accessible to you through your authenticated account. No third-party analytics or advertising services are used.',
            ),
            const SizedBox(height: 16),

            // Backup & Export
            _buildPolicyCard(
              icon: Icons.backup_rounded,
              title: 'Backup & Data Export',
              content:
                  'You have full control over your data:\n\n'
                  '• Create backups of all transactions to cloud storage.\n'
                  '• Restore data from previous backups.\n'
                  '• Export financial reports as PDF documents.\n'
                  '• Delete all data permanently from settings.',
            ),
            const SizedBox(height: 16),

            // Log Data
            _buildPolicyCard(
              icon: Icons.bug_report_rounded,
              title: 'Log Data',
              content:
                  'In case of an error, the app may collect data and information called Log Data. This may include your device IP address, device name, operating system version, and other diagnostic information to help fix issues.',
            ),
            const SizedBox(height: 16),

            // Cookies
            _buildPolicyCard(
              icon: Icons.cookie_rounded,
              title: 'Cookies',
              content:
                  'This app does not use cookies directly. However, third-party services used within the app (such as Firebase) may use cookies to improve their services.',
            ),
            const SizedBox(height: 16),

            // Children's Privacy
            _buildPolicyCard(
              icon: Icons.family_restroom_rounded,
              title: "Children's Privacy",
              content:
                  'This app does not knowingly collect personally identifiable information from children under 13. If you believe we have inadvertently collected such information, please contact us immediately.',
            ),
            const SizedBox(height: 16),

            // Changes to Policy
            _buildPolicyCard(
              icon: Icons.change_history_rounded,
              title: 'Changes to This Privacy Policy',
              content:
                  'We may update our Privacy Policy from time to time. You are advised to review this page periodically for any changes. We will notify you of any changes by posting the new policy in the app.',
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
                    'If you have any questions about this Privacy Policy, please contact us:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                  const SizedBox(height: 16),
                  // Email Button
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
                  const SizedBox(height: 12),
                  // Privacy Policy Link
                  InkWell(
                    onTap: () => _launchUrl(_privacyUrl),
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
                            Icons.language_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Privacy Policy Online',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'www.expenso.com/privacy',
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
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
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
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
