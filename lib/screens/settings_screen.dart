// lib/screens/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'password_change_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentUserId;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Settings values
  String _selectedCurrency = 'INR';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserSettings();
  }

  // ==================== LOAD USER SETTINGS ====================
  Future<void> _loadUserSettings() async {
    if (_currentUserId == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userData = data;
          _selectedCurrency = data['defaultCurrency'] ?? 'INR';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== SAVE SETTING ====================
  Future<void> _saveSetting(String key, dynamic value) async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .update({key: value});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setting updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  // ==================== BACKUP DATA ====================
  Future<void> _backupData() async {
    if (_currentUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.backup_outlined, color: Color(0xFF3498DB)),
            SizedBox(width: 8),
            Text('Backup Data'),
          ],
        ),
        content: const Text(
          'This will create a backup of all your transactions and settings. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
            ),
            child: const Text('Backup Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF3498DB)),
              SizedBox(height: 16),
              Text(
                'Creating backup...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

      final firestore = FirebaseFirestore.instance;
      final backupId = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // 1. Backup user data
      final userDoc = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .get();
      if (userDoc.exists) {
        await firestore
            .collection('ExpensoUsers')
            .doc(_currentUserId)
            .collection('backups')
            .doc(backupId)
            .collection('data')
            .doc('profile')
            .set(userDoc.data()!);
      }

      // 2. Backup transactions
      final transactions = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .get();

      int transactionCount = 0;
      for (var doc in transactions.docs) {
        await firestore
            .collection('ExpensoUsers')
            .doc(_currentUserId)
            .collection('backups')
            .doc(backupId)
            .collection('data')
            .doc('transactions')
            .collection('items')
            .doc(doc.id)
            .set(doc.data()!);
        transactionCount++;
      }

      // 3. Backup settings
      final settingsDoc = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('quickCategories')
          .get();

      if (settingsDoc.exists) {
        await firestore
            .collection('ExpensoUsers')
            .doc(_currentUserId)
            .collection('backups')
            .doc(backupId)
            .collection('data')
            .doc('settings')
            .set(settingsDoc.data()!);
      }

      // 4. Save backup metadata
      await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('backups')
          .doc(backupId)
          .set({
            'backupId': backupId,
            'createdAt': FieldValue.serverTimestamp(),
            'transactionCount': transactionCount,
            'totalExpense': _getTotalFromTransactions(transactions),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backup complete! $transactionCount transactions saved.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== RESTORE DATA ====================
  Future<void> _restoreData() async {
    if (_currentUserId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFE67E22)),
              SizedBox(height: 16),
              Text(
                'Loading backups...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

      final firestore = FirebaseFirestore.instance;
      final backupsSnapshot = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) Navigator.pop(context);

      if (backupsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backups found! Create a backup first.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (mounted) {
        _showRestoreDialog(backupsSnapshot.docs);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== SHOW RESTORE DIALOG ====================
  void _showRestoreDialog(List<QueryDocumentSnapshot> backups) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore_outlined, color: Color(0xFFE67E22)),
            SizedBox(width: 8),
            Text('Select Backup'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final backup = backups[index];
              final data = backup.data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null
                  ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(createdAt.toDate())
                  : 'Unknown date';
              final count = data['transactionCount'] ?? 0;
              final total = data['totalExpense'] ?? 0.0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud_download,
                    color: Color(0xFFE67E22),
                    size: 20,
                  ),
                ),
                title: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$count transactions • ₹${NumberFormat('#,###').format(total)}',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _performRestore(backup.id);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ==================== PERFORM RESTORE ====================
  Future<void> _performRestore(String backupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Restore'),
          ],
        ),
        content: const Text(
          'This will replace all current transactions with the backup data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFE67E22)),
              SizedBox(height: 16),
              Text(
                'Restoring data...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

      final firestore = FirebaseFirestore.instance;

      // 1. Delete current transactions
      final currentTransactions = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .get();

      for (var doc in currentTransactions.docs) {
        await doc.reference.delete();
      }

      // 2. Restore transactions from backup
      final backupTransactions = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('backups')
          .doc(backupId)
          .collection('data')
          .doc('transactions')
          .collection('items')
          .get();

      int restoredCount = 0;
      for (var doc in backupTransactions.docs) {
        await firestore
            .collection('ExpensoUsers')
            .doc(_currentUserId)
            .collection('transactions')
            .doc(doc.id)
            .set(doc.data()!);
        restoredCount++;
      }

      // 3. Restore settings
      final backupSettings = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('backups')
          .doc(backupId)
          .collection('data')
          .doc('settings')
          .get();

      if (backupSettings.exists) {
        await firestore
            .collection('ExpensoUsers')
            .doc(_currentUserId)
            .collection('settings')
            .doc('quickCategories')
            .set(backupSettings.data()!);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restore complete! $restoredCount transactions restored.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper: Get total from transactions
  double _getTotalFromTransactions(QuerySnapshot transactions) {
    double total = 0;
    for (var doc in transactions.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ==================== LOGOUT ====================
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Account Section
                  _buildSectionTitle('Account'),
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
                        _buildSettingTile(
                          icon: Icons.person_outlined,
                          iconColor: const Color(0xFF3498DB),
                          title: 'Edit Profile',
                          subtitle: 'Name, phone, business details',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingTile(
                          icon: Icons.lock_outline,
                          iconColor: const Color(0xFFE74C3C),
                          title: 'Change Password',
                          subtitle: 'Update your account password',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PasswordChangeScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Data Section
                  _buildSectionTitle('Data'),
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
                        _buildSettingTile(
                          icon: Icons.backup_outlined,
                          iconColor: const Color(0xFF3498DB),
                          title: 'Backup Data',
                          subtitle: 'Save all transactions to cloud',
                          onTap: _backupData,
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingTile(
                          icon: Icons.restore_outlined,
                          iconColor: const Color(0xFFE67E22),
                          title: 'Restore Data',
                          subtitle: 'Restore from previous backup',
                          onTap: _restoreData,
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingTile(
                          icon: Icons.delete_outline,
                          iconColor: Colors.red,
                          title: 'Clear All Data',
                          subtitle: 'Delete all transactions',
                          titleColor: Colors.red,
                          onTap: _showClearDataDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // About Section
                  _buildSectionTitle('About'),
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
                        _buildSettingTile(
                          icon: Icons.info_outline,
                          iconColor: Colors.grey,
                          title: 'App Version',
                          subtitle: '1.0.0',
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: Colors.grey,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingTile(
                          icon: Icons.description_outlined,
                          iconColor: Colors.grey,
                          title: 'Terms of Service',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  // ==================== SETTING TILE ====================
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? const Color(0xFF1E293B),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF94A3B8),
                )
              : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ==================== CLEAR DATA DIALOG ====================
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    if (_currentUserId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final firestore = FirebaseFirestore.instance;

      final transactions = await firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .get();

      for (var doc in transactions.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== HELPER ====================
}
