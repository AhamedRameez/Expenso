// lib/screens/debit_edit_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebitEditScreen extends StatefulWidget {
  final Map<String, dynamic> debit;

  const DebitEditScreen({super.key, required this.debit});

  @override
  State<DebitEditScreen> createState() => _DebitEditScreenState();
}

class _DebitEditScreenState extends State<DebitEditScreen> {
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addMoreAmountController =
      TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _currentUserId;
  late Map<String, dynamic> _debit;
  DateTime _dateBorrowed = DateTime.now();
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _debit = Map<String, dynamic>.from(widget.debit);
    _personNameController.text = _debit['personName'] as String? ?? '';
    _purposeController.text = _debit['purpose'] as String? ?? '';
    _contactController.text = _debit['contact'] as String? ?? '';
    _notesController.text = _debit['notes'] as String? ?? '';
    if (_debit['dateBorrowed'] is Timestamp)
      _dateBorrowed = (_debit['dateBorrowed'] as Timestamp).toDate();
    if (_debit['dueDate'] is Timestamp)
      _dueDate = (_debit['dueDate'] as Timestamp).toDate();
    _amountController.text = ((_debit['amount'] as num?)?.toDouble() ?? 0)
        .toStringAsFixed(0);
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

  Future<void> _updateDebit() async {
    final name = _personNameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty) {
      _showError('Please enter name');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Please enter valid amount');
      return;
    }
    final alreadyPaid = (_debit['paidAmount'] as num?)?.toDouble() ?? 0;
    final newStatus = alreadyPaid >= amount
        ? 'paid'
        : (alreadyPaid > 0 ? 'partial' : 'pending');
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('debits')
          .doc(_debit['id'])
          .update({
            'personName': name,
            'purpose': _purposeController.text.trim(),
            'amount': amount,
            'paidAmount': alreadyPaid,
            'status': newStatus,
            'dateBorrowed': Timestamp.fromDate(_dateBorrowed),
            'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
            'contact': _contactController.text.trim(),
            'notes': _notesController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        _showSnackBar('Updated!', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addMoreBorrowed() async {
    final addAmount = double.tryParse(_addMoreAmountController.text.trim());
    if (addAmount == null || addAmount <= 0) {
      _showError('Enter valid amount');
      return;
    }
    final currentAmount = (_debit['amount'] as num?)?.toDouble() ?? 0;
    final newTotal = currentAmount + addAmount;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Color(0xFFE74C3C)),
            SizedBox(width: 8),
            Text('Borrowed More?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              'Current',
              '₹${NumberFormat('#,###').format(currentAmount)}',
            ),
            _infoRow('Adding', '+ ₹${NumberFormat('#,###').format(addAmount)}'),
            const Divider(),
            _infoRow(
              'New Total',
              '₹${NumberFormat('#,###').format(newTotal)}',
              bold: true,
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
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isSaving = true);
    try {
      final alreadyPaid = (_debit['paidAmount'] as num?)?.toDouble() ?? 0;
      final newStatus = alreadyPaid >= newTotal
          ? 'paid'
          : (alreadyPaid > 0 ? 'partial' : 'pending');
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('debits')
          .doc(_debit['id'])
          .update({
            'amount': newTotal,
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('debits')
          .doc(_debit['id'])
          .collection('payments')
          .add({
            'amount': addAmount,
            'date': Timestamp.fromDate(DateTime.now()),
            'type': 'added_money',
          });
      setState(() {
        _debit['amount'] = newTotal;
        _debit['status'] = newStatus;
        _amountController.text = newTotal.toStringAsFixed(0);
      });
      _addMoreAmountController.clear();
      if (mounted)
        _showSnackBar(
          'Added ₹${NumberFormat('#,###').format(addAmount)}!',
          Colors.green,
        );
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
  void _showSnackBar(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
        ),
      );
  Widget _infoRow(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          v,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: bold ? const Color(0xFFE74C3C) : Colors.black87,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yy');
    final cf = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final amount = (_debit['amount'] as num?)?.toDouble() ?? 0;
    final paid = (_debit['paidAmount'] as num?)?.toDouble() ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Edit Debit',
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
            onPressed: _isSaving ? null : _updateDebit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total', cf.format(amount)),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _statItem('Paid', cf.format(paid)),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _statItem('Remaining', cf.format(amount - paid)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFFE74C3C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Borrowed More Money',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'If you borrowed additional money',
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
                          decoration: InputDecoration(
                            hintText: 'Additional amount',
                            prefixIcon: const Icon(
                              Icons.currency_rupee,
                              size: 18,
                              color: Color(0xFFE74C3C),
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
                        onPressed: _isSaving ? null : _addMoreBorrowed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
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
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Edit Details', Icons.edit_outlined),
                  const SizedBox(height: 14),
                  _buildField(
                    _personNameController,
                    'Person / Business Name *',
                    'Who do you owe?',
                    Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _purposeController,
                    'Purpose',
                    'Reason for borrowing',
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _amountController,
                    'Total Amount *',
                    'Update total',
                    Icons.currency_rupee,
                    kb: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    _contactController,
                    'Contact',
                    'Phone or email',
                    Icons.contact_phone_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildLabel('Date Borrowed'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _dateBorrowed,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setState(() => _dateBorrowed = p);
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
                            color: Color(0xFFE74C3C),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            dateFormat.format(_dateBorrowed),
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
                  _buildLabel('Due Date (Optional)'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (p != null) setState(() => _dueDate = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dueDate != null
                              ? const Color(0xFFE74C3C).withOpacity(0.5)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 18,
                            color: _dueDate != null
                                ? const Color(0xFFE74C3C)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _dueDate != null
                                ? dateFormat.format(_dueDate!)
                                : 'Tap to set',
                            style: TextStyle(
                              fontSize: 14,
                              color: _dueDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (_dueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _dueDate = null),
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
                    'Additional details...',
                    Icons.edit_note,
                    ml: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateDebit,
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
                        backgroundColor: const Color(0xFFE74C3C),
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

  Widget _sectionTitle(String t, IconData i) => Row(
    children: [
      Container(
        width: 3,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Icon(i, size: 18, color: const Color(0xFFE74C3C)),
      const SizedBox(width: 6),
      Text(
        t,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
    ],
  );
  Widget _buildLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF64748B),
    ),
  );

  Widget _buildField(
    TextEditingController c,
    String l,
    String h,
    IconData i, {
    TextInputType kb = TextInputType.text,
    int ml = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: kb,
          maxLines: ml,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: h,
            prefixIcon: Icon(i, size: 18, color: const Color(0xFFE74C3C)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: ml > 1 ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String l, String v) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(l, style: TextStyle(fontSize: 11, color: Colors.white70)),
    ],
  );
}
