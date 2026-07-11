// lib/screens/profile_screen.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _businessNameFocus = FocusNode();
  final FocusNode _phone1Focus = FocusNode();
  final FocusNode _phone2Focus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ==================== LOAD USER DATA ====================
  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot userDoc = await firestore
          .collection('ExpensoUsers')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        print('✅ Profile - User data loaded successfully');

        setState(() {
          _userData = data;
          _isLoading = false;
        });

        // Populate controllers
        _nameController.text = data['name'] ?? '';
        _businessNameController.text = data['businessName'] ?? '';
        _phone1Controller.text = data['phone1'] ?? '';
        _phone2Controller.text = data['phone2'] ?? '';
        _addressController.text = data['address'] ?? '';
      }
    } catch (e) {
      print('❌ Profile - Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== SAVE PROFILE ====================
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final firestore = FirebaseFirestore.instance;

      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
        'phone1': _phone1Controller.text.trim(),
        'phone2': _phone2Controller.text.trim().isEmpty
            ? null
            : _phone2Controller.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove null values
      updatedData.removeWhere((key, value) => value == null);

      await firestore
          .collection('ExpensoUsers')
          .doc(currentUser.uid)
          .update(updatedData);

      // Update local data
      setState(() {
        _userData?.addAll(updatedData);
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Profile - Error saving: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: Color(0xFF475569),
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        actions: [
          // Edit/Save Toggle Button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isEditing
                  ? const Color(0xFF27AE60).withOpacity(0.1)
                  : const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                size: 20,
                color: _isEditing
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF6366F1),
              ),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            _buildProfileHeader(),
            const SizedBox(height: 20),

            // Account Info Section
            _buildSection(
              title: 'Account Information',
              icon: Icons.account_circle_outlined,
              color: const Color(0xFF6366F1),
              children: [
                _buildInfoRow(
                  label: 'Email',
                  value: _userData?['email'] ?? 'N/A',
                  icon: Icons.email_outlined,
                  isEditable: false,
                ),
                _buildInfoRow(
                  label: 'User Type',
                  value: _getUserTypeLabel(
                    _userData?['userType'] ?? 'personal',
                  ),
                  icon: Icons.person_outline,
                  isEditable: false,
                  valueColor: const Color(0xFF6366F1),
                ),
                _buildInfoRow(
                  label: 'Member Since',
                  value: _getFormattedDate(_userData?['createdAt']),
                  icon: Icons.calendar_today_outlined,
                  isEditable: false,
                ),
                _buildInfoRow(
                  label: 'Account Status',
                  value: _userData?['isActive'] == true ? 'Active' : 'Inactive',
                  icon: Icons.verified_outlined,
                  isEditable: false,
                  valueColor: _userData?['isActive'] == true
                      ? const Color(0xFF27AE60)
                      : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Personal Info Section
            _buildSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              color: const Color(0xFF8B5CF6),
              children: [
                _buildEditableField(
                  label: 'Full Name',
                  controller: _nameController,
                  focusNode: _nameFocus,
                  icon: Icons.person_outline,
                  isEditing: _isEditing,
                ),
                const SizedBox(height: 4),
                _buildEditableField(
                  label: 'Business Name',
                  controller: _businessNameController,
                  focusNode: _businessNameFocus,
                  icon: Icons.business_outlined,
                  isEditing: _isEditing,
                  isOptional: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contact Info Section
            _buildSection(
              title: 'Contact Information',
              icon: Icons.contact_phone_outlined,
              color: const Color(0xFF10B981),
              children: [
                _buildEditableField(
                  label: 'Phone Number 1 (Primary)',
                  controller: _phone1Controller,
                  focusNode: _phone1Focus,
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  isEditing: _isEditing,
                ),
                const SizedBox(height: 4),
                _buildEditableField(
                  label: 'Phone Number 2 (Optional)',
                  controller: _phone2Controller,
                  focusNode: _phone2Focus,
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  isEditing: _isEditing,
                  isOptional: true,
                ),
                const SizedBox(height: 4),
                _buildEditableField(
                  label: 'Address',
                  controller: _addressController,
                  focusNode: _addressFocus,
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                  isEditing: _isEditing,
                  isOptional: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save Button (visible only in edit mode)
            if (_isEditing)
              Container(
                width: double.infinity,
                height: 52,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: const Color(
                      0xFF6366F1,
                    ).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

            // Cancel Button (visible only in edit mode)
            if (_isEditing)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    // Reset controllers to original values
                    _nameController.text = _userData?['name'] ?? '';
                    _businessNameController.text =
                        _userData?['businessName'] ?? '';
                    _phone1Controller.text = _userData?['phone1'] ?? '';
                    _phone2Controller.text = _userData?['phone2'] ?? '';
                    _addressController.text = _userData?['address'] ?? '';
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE HEADER ====================
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _userData?['name'] ?? 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            _userData?['email'] ?? '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),

          // User Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getUserTypeLabel(_userData?['userType'] ?? 'personal'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION BUILDER ====================
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ==================== INFO ROW (Non-editable) ====================
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    bool isEditable = true,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  // ==================== EDITABLE FIELD ====================
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isEditing = false,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              if (isOptional)
                Text(
                  ' (Optional)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isEditing)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: focusNode.hasFocus
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE2E8F0),
                  width: focusNode.hasFocus ? 1.5 : 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    icon,
                    size: 18,
                    color: focusNode.hasFocus
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: maxLines > 1 ? 14 : 12,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Not set' : controller.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: controller.text.isEmpty
                            ? Colors.grey.shade400
                            : const Color(0xFF1E293B),
                      ),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isEditing)
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case 'business':
        return '💼 Business User';
      case 'personal':
        return '👤 Personal User';
      case 'both':
        return '🔄 Both (Business & Personal)';
      default:
        return userType;
    }
  }

  String _getFormattedDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'N/A';
      }
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _nameFocus.dispose();
    _businessNameFocus.dispose();
    _phone1Focus.dispose();
    _phone2Focus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }
}
