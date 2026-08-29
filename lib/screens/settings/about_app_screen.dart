// lib/screens/about_app_screen.dart
import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo & Name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EXPENSO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart Expense Tracker',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Info Section
            _buildSectionTitle('App Information'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF6366F1),
                    title: 'App Name',
                    value: 'Expenso',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.verified,
                    iconColor: const Color(0xFF27AE60),
                    title: 'Version',
                    value: '1.0.0',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.build_outlined,
                    iconColor: const Color(0xFFF39C12),
                    title: 'Build',
                    value: '2025.07.15 (Release)',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.code,
                    iconColor: const Color(0xFF3498DB),
                    title: 'Framework',
                    value: 'Flutter 3.x',
                  ),
                  // const Divider(height: 1, indent: 56),
                  // _buildInfoTile(
                  //   icon: Icons.cloud_outlined,
                  //   iconColor: const Color(0xFF9B59B6),
                  //   title: 'Backend',
                  //   value: 'Firebase',
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Features Section
            _buildSectionTitle('Key Features'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFeatureTile(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF27AE60),
                    title: 'Income Tracking',
                    description: 'Track all your income sources easily',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildFeatureTile(
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFE74C3C),
                    title: 'Expense Management',
                    description: 'Manage and categorize your expenses',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildFeatureTile(
                    icon: Icons.assessment,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Reports & Analytics',
                    description: 'Visual reports with PDF export',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildFeatureTile(
                    icon: Icons.calculate_outlined,
                    iconColor: const Color(0xFFF39C12),
                    title: 'Expense Planner',
                    description: 'Plan and budget monthly expenses',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildFeatureTile(
                    icon: Icons.backup_outlined,
                    iconColor: const Color(0xFF3498DB),
                    title: 'Backup & Restore',
                    description: 'Secure cloud backup of your data',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildFeatureTile(
                    icon: Icons.lock_outlined,
                    iconColor: const Color(0xFF9B59B6),
                    title: 'Secure',
                    description: 'Firebase authentication & data security',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Developer Section
            _buildSectionTitle('Developer'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Developed By',
                    value: 'Saktechnosolution',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFFE74C3C),
                    title: 'Contact',
                    value: 'saktechnosolution@gmail.com',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.language,
                    iconColor: const Color(0xFF27AE60),
                    title: 'Website',
                    value: 'www.saktechnosolution.com',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // // Legal Section
            // _buildSectionTitle('Legal'),
            // const SizedBox(height: 8),
            // Container(
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.grey.withOpacity(0.05),
            //         blurRadius: 8,
            //         offset: const Offset(0, 2),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     children: [
            //       _buildSettingTile(
            //         icon: Icons.privacy_tip_outlined,
            //         iconColor: const Color(0xFF6366F1),
            //         title: 'Privacy Policy',
            //         onTap: () {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             const SnackBar(
            //               content: Text('Privacy Policy page coming soon!'),
            //             ),
            //           );
            //         },
            //       ),
            //       const Divider(height: 1, indent: 56),
            //       _buildSettingTile(
            //         icon: Icons.description_outlined,
            //         iconColor: const Color(0xFF27AE60),
            //         title: 'Terms of Service',
            //         onTap: () {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             const SnackBar(
            //               content: Text('Terms of Service page coming soon!'),
            //             ),
            //           );
            //         },
            //       ),
            //       const Divider(height: 1, indent: 56),
            //       _buildSettingTile(
            //         icon: Icons.star_outline,
            //         iconColor: const Color(0xFFF39C12),
            //         title: 'Rate This App',
            //         onTap: () {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             const SnackBar(
            //               content: Text('Thank you for your support! ⭐'),
            //             ),
            //           );
            //         },
            //       ),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 20),

            // Copyright
            Center(
              child: Text(
                '© 2026 Saktechnosolution. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================== SECTION TITLE ====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ==================== INFO TILE ====================
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ==================== FEATURE TILE ====================
  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ==================== SETTING TILE ====================
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: Color(0xFF94A3B8),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
