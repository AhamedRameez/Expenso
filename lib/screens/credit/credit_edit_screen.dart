// lib/screens/credit_edit_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditEditScreen extends StatefulWidget {
  final Map<String, dynamic> credit;

  const CreditEditScreen({super.key, required this.credit});

  @override
  State<CreditEditScreen> createState() => _CreditEditScreenState();
}

class _CreditEditScreenState extends State<CreditEditScreen> {
  // ==================== CONTROLLERS ====================
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addMoreAmountController =
      TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ==================== VARIABLES ====================
  String? _currentUserId;
  late Map<String, dynamic> _credit;
  DateTime _dateGiven = DateTime.now();
  DateTime? _expectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _credit = Map<String, dynamic>.from(widget.credit);
    _loadCreditData();
  }

  void _loadCreditData() {
    _personNameController.text = _credit['personName'] as String? ?? '';
    _purposeController.text = _credit['purpose'] as String? ?? '';
    _contactController.text = _credit['contact'] as String? ?? '';
    _notesController.text = _credit['notes'] as String? ?? '';

    if (_credit['dateGiven'] is Timestamp) {
      _dateGiven = (_credit['dateGiven'] as Timestamp).toDate();
    }
    if (_credit['expectedDate'] is Timestamp) {
      _expectedDate = (_credit['expectedDate'] as Timestamp).toDate();
    }

    final amount = (_credit['amount'] as num?)?.toDouble() ?? 0;
    _amountController.text = amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _addMoreAmountController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ==================== UPDATE CREDIT ====================
  Future<void> _updateCredit() async {
    final name = _personNameController.text.trim();
    final amountText = _amountController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter person/business name');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid total amount');
      return;
    }

    final alreadyPaid = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
    final newStatus = alreadyPaid >= amount
        ? 'paid'
        : (alreadyPaid > 0 ? 'partial' : 'pending');

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .update({
            'personName': name,
            'purpose': _purposeController.text.trim(),
            'amount': amount,
            'paidAmount': alreadyPaid,
            'status': newStatus,
            'dateGiven': Timestamp.fromDate(_dateGiven),
            'expectedDate': _expectedDate != null
                ? Timestamp.fromDate(_expectedDate!)
                : null,
            'contact': _contactController.text.trim(),
            'notes': _notesController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Credit updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== ADD MORE MONEY ====================
  Future<void> _addMoreMoney() async {
    final addAmountText = _addMoreAmountController.text.trim();
    final addAmount = double.tryParse(addAmountText);

    if (addAmount == null || addAmount <= 0) {
      _showError('Please enter a valid amount to add');
      return;
    }

    final currentAmount = (_credit['amount'] as num?)?.toDouble() ?? 0;
    final newTotal = currentAmount + addAmount;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Add More Money?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              'Current Amount',
              '₹${NumberFormat('#,###').format(currentAmount)}',
            ),
            _infoRow('Adding', '+ ₹${NumberFormat('#,###').format(addAmount)}'),
            const Divider(),
            _infoRow(
              'New Total',
              '₹${NumberFormat('#,###').format(newTotal)}',
              bold: true,
            ),
            const SizedBox(height: 8),
            Text(
              'This means you gave additional money to this person.\nThis will be recorded in the payment history.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Confirm Add'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final alreadyPaid = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
      final newStatus = alreadyPaid >= newTotal
          ? 'paid'
          : (alreadyPaid > 0 ? 'partial' : 'pending');

      // Update credit amount
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .update({
            'amount': newTotal,
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // 🆕 Save payment record for added money
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .collection('payments')
          .add({
            'amount': addAmount,
            'date': Timestamp.fromDate(DateTime.now()),
            'type': 'added_money',
          });

      setState(() {
        _credit['amount'] = newTotal;
        _credit['status'] = newStatus;
        _amountController.text = newTotal.toStringAsFixed(0);
      });

      _addMoreAmountController.clear();

      if (mounted) {
        _showSnackBar(
          'Added ₹${NumberFormat('#,###').format(addAmount)}! New total: ₹${NumberFormat('#,###').format(newTotal)}',
          Colors.green,
        );
      }
    } catch (e) {
      _showError('Failed to add: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== HELPERS ====================
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? const Color(0xFF6366F1) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yy');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final currentAmount = (_credit['amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
    final remaining = currentAmount - paidAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Edit Credit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_rounded,
              size: 24,
              color: Color(0xFF27AE60),
            ),
            tooltip: 'Save Changes',
            onPressed: _isSaving ? null : _updateCredit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total', currencyFormat.format(currentAmount)),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _statItem('Paid', currencyFormat.format(paidAmount)),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _statItem('Remaining', currencyFormat.format(remaining)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Add More Money Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add More Money',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'If you gave additional money to this person',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _addMoreAmountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter additional amount',
                            prefixIcon: const Icon(
                              Icons.currency_rupee,
                              size: 18,
                              color: Color(0xFF6366F1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _addMoreMoney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Edit Form Card
            Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Edit Details', Icons.edit_outlined),
                  const SizedBox(height: 14),
                  _buildField(
                    _personNameController,
                    'Person / Business Name *',
                    'Who owes you money?',
                    Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _purposeController,
                    'Purpose / Reason',
                    'e.g., Hospital loan, Project payment',
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _amountController,
                    'Total Amount *',
                    'Update total amount if needed',
                    Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _contactController,
                    'Contact',
                    'Phone number or email',
                    Icons.contact_phone_outlined,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Date Given'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateGiven,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dateGiven = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            dateFormat.format(_dateGiven),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Expected Return Date (Optional)'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null)
                        setState(() => _expectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _expectedDate != null
                              ? const Color(0xFF6366F1).withOpacity(0.5)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 18,
                            color: _expectedDate != null
                                ? const Color(0xFF6366F1)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _expectedDate != null
                                ? dateFormat.format(_expectedDate!)
                                : 'Tap to set',
                            style: TextStyle(
                              fontSize: 14,
                              color: _expectedDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (_expectedDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _expectedDate = null),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _notesController,
                    'Notes',
                    'Any additional details...',
                    Icons.edit_note,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateCredit,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        disabledBackgroundColor: const Color(
                          0xFF6366F1,
                        ).withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  // ==================== WIDGET HELPERS ====================
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
