// lib/screens/expense_calculation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseCalculationScreen extends StatefulWidget {
  const ExpenseCalculationScreen({super.key});

  @override
  State<ExpenseCalculationScreen> createState() =>
      _ExpenseCalculationScreenState();
}

class _ExpenseCalculationScreenState extends State<ExpenseCalculationScreen> {
  // ==================== CONTROLLERS ====================
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  // ==================== VARIABLES ====================
  List<Map<String, dynamic>> _plannedExpenses = [];
  double _monthlyIncome = 0;
  bool _isIncomeSet = false;
  DateTime _selectedMonth = DateTime.now();
  String? _currentUserId;

  // Quick Categories
  List<String> _quickCategories = [
    'Rent/Mortgage',
    'Groceries',
    'Transport',
    'Utilities',
    'Phone/Internet',
    'Insurance',
    'Entertainment',
    'Shopping',
    'Healthcare',
    'Education',
    'Savings',
    'Dining Out',
  ];

  // Category icons
  final Map<String, String> _categoryIcons = {
    'Rent/Mortgage': '🏠',
    'Groceries': '🛒',
    'Transport': '🚗',
    'Utilities': '💡',
    'Phone/Internet': '📱',
    'Insurance': '🛡️',
    'Entertainment': '🎬',
    'Shopping': '🛍️',
    'Healthcare': '🏥',
    'Education': '📚',
    'Savings': '💰',
    'Dining Out': '🍽️',
  };

  // Saved plans
  List<Map<String, dynamic>> _savedPlans = [];
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadQuickCategories();
    _loadSavedPlans();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _monthlyIncomeController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  // ==================== LOAD QUICK CATEGORIES FROM FIRESTORE ====================
  Future<void> _loadQuickCategories() async {
    if (_currentUserId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('quickCategories')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _quickCategories = List<String>.from(
            data['categories'] ?? _quickCategories,
          );
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // ==================== SAVE QUICK CATEGORIES ====================
  Future<void> _saveQuickCategories() async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('settings')
          .doc('quickCategories')
          .set({'categories': _quickCategories});
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  // ==================== ADD QUICK CATEGORY ====================
  void _addQuickCategory() {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    if (_quickCategories.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _quickCategories.add(name);
      _newCategoryController.clear();
    });
    _saveQuickCategories();
    Navigator.pop(context);
  }

  // ==================== REMOVE QUICK CATEGORY ====================
  void _removeQuickCategory(String category) {
    setState(() {
      _quickCategories.remove(category);
    });
    _saveQuickCategories();
  }

  // ==================== SHOW ADD CATEGORY DIALOG ====================
  void _showAddCategoryDialog() {
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Quick Category'),
        content: TextField(
          controller: _newCategoryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addQuickCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ==================== LOAD SAVED PLANS ====================
  Future<void> _loadSavedPlans() async {
    if (_currentUserId == null) return;

    setState(() => _isLoadingSaved = true);

    try {
      final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
      final doc = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('monthlyPlans')
          .doc(monthKey)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _monthlyIncome = (data['income'] as num?)?.toDouble() ?? 0;
          _isIncomeSet = data['income'] != null;
          _plannedExpenses = List<Map<String, dynamic>>.from(
            data['expenses'] ?? [],
          );
        });
      } else {
        // Load empty for this month
        setState(() {
          _monthlyIncome = 0;
          _isIncomeSet = false;
          _plannedExpenses = [];
        });
      }
    } catch (e) {
      print('Error loading plans: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  // ==================== SAVE PLAN FOR MONTH ====================
  Future<void> _savePlanForMonth() async {
    if (_currentUserId == null) return;

    if (!_isIncomeSet || _plannedExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set income and add at least one expense'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('monthlyPlans')
          .doc(monthKey)
          .set({
            'income': _monthlyIncome,
            'expenses': _plannedExpenses,
            'totalPlanned': _totalPlanned,
            'remaining': _remaining,
            'month': monthKey,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan saved for ${DateFormat('MMMM yyyy').format(_selectedMonth)}!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== ADD EXPENSE ITEM ====================
  void _addExpenseItem() {
    final name = _itemNameController.text.trim();
    final amountText = _amountController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter item name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _plannedExpenses.add({
        'name': name,
        'amount': amount,
        'isChecked': false,
      });
      _itemNameController.clear();
      _amountController.clear();
    });
  }

  // ==================== ADD SUGGESTED CATEGORY ====================
  void _addSuggestedCategory(String name) {
    setState(() {
      _itemNameController.text = name;
    });
  }

  // ==================== REMOVE EXPENSE ITEM ====================
  void _removeExpenseItem(int index) {
    setState(() {
      _plannedExpenses.removeAt(index);
    });
  }

  // ==================== TOGGLE CHECK ====================
  void _toggleCheck(int index) {
    setState(() {
      _plannedExpenses[index]['isChecked'] =
          !_plannedExpenses[index]['isChecked'];
    });
  }

  // ==================== SET INCOME ====================
  void _setIncome() {
    final incomeText = _monthlyIncomeController.text.trim();
    final income = double.tryParse(incomeText);

    if (income == null || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid income'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _monthlyIncome = income;
      _isIncomeSet = true;
    });
  }

  // ==================== CHANGE MONTH ====================
  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _loadSavedPlans();
    }
  }

  // ==================== CLEAR ALL ====================
  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All?'),
        content: const Text('Remove all planned expenses for this month?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _plannedExpenses.clear();
                _monthlyIncome = 0;
                _isIncomeSet = false;
                _monthlyIncomeController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==================== GET TOTALS ====================
  double get _totalPlanned {
    return _plannedExpenses.fold(
      0,
      (sum, item) => sum + (item['amount'] as double),
    );
  }

  double get _remaining {
    return _monthlyIncome - _totalPlanned;
  }

  double get _spentPercentage {
    if (_monthlyIncome == 0) return 0;
    return (_totalPlanned / _monthlyIncome) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Expense Planner',
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
        actions: [
          // Save Button
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Color(0xFF6366F1)),
            tooltip: 'Save Plan',
            onPressed: _savePlanForMonth,
          ),
          if (_plannedExpenses.isNotEmpty || _isIncomeSet)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoadingSaved
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month Selector
                  _buildMonthSelector(),
                  const SizedBox(height: 12),

                  // Income Card
                  _buildIncomeCard(currencyFormat),
                  const SizedBox(height: 16),

                  // Add Expense Form
                  _buildAddExpenseForm(),
                  const SizedBox(height: 16),

                  // Quick Categories
                  _buildQuickCategories(),
                  const SizedBox(height: 16),

                  // Planned Expenses List
                  _buildPlannedExpensesList(currencyFormat),
                  const SizedBox(height: 16),

                  // Summary Card
                  if (_plannedExpenses.isNotEmpty && _isIncomeSet) ...[
                    _buildSummaryCard(currencyFormat),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==================== MONTH SELECTOR ====================
  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _selectMonth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month,
              size: 18,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ==================== INCOME CARD ====================
  Widget _buildIncomeCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wallet, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Monthly Income',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isIncomeSet)
            Row(
              children: [
                Expanded(
                  child: Text(
                    currencyFormat.format(_monthlyIncome),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isIncomeSet = false),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monthlyIncomeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Enter monthly income',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.currency_rupee,
                        color: Colors.white70,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _setIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Set',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==================== ADD EXPENSE FORM ====================
  Widget _buildAddExpenseForm() {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text(
            'Add Planned Expense',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemNameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Item name',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: Color(0xFFE74C3C),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE74C3C)),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: Color(0xFFE74C3C),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE74C3C)),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addExpenseItem,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== QUICK CATEGORIES ====================
  Widget _buildQuickCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Add Categories',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            GestureDetector(
              onTap: _showAddCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Color(0xFF6366F1)),
                    SizedBox(width: 2),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickCategories.map((category) {
            return Container(
              padding: const EdgeInsets.only(
                left: 10,
                top: 6,
                bottom: 6,
                right: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category text - tap to use
                  GestureDetector(
                    onTap: () {
                      _itemNameController.text = category;
                      _amountController.clear();
                    },
                    child: Text(
                      '${_categoryIcons[category] ?? '📌'}  $category',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // ✕ Delete button
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text('Remove "$category"?'),
                          content: const Text('Remove this quick category?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _removeQuickCategory(category);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Remove',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== PLANNED EXPENSES LIST ====================
  Widget _buildPlannedExpensesList(NumberFormat currencyFormat) {
    if (_plannedExpenses.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              const Text(
                'Planned Expenses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                '${_plannedExpenses.length} items',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._plannedExpenses.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleCheck(index),
                    child: Icon(
                      item['isChecked']
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: item['isChecked']
                          ? const Color(0xFF27AE60)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: item['isChecked']
                            ? Colors.grey.shade400
                            : const Color(0xFF1E293B),
                        decoration: item['isChecked']
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(item['amount']),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item['isChecked']
                          ? Colors.grey.shade400
                          : const Color(0xFFE74C3C),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _removeExpenseItem(index),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Planned',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  currencyFormat.format(_totalPlanned),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SUMMARY CARD ====================
  Widget _buildSummaryCard(NumberFormat currencyFormat) {
    final isOverBudget = _totalPlanned > _monthlyIncome;
    final isNearBudget = _spentPercentage >= 80 && _spentPercentage <= 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverBudget
              ? [const Color(0xFFE74C3C), const Color(0xFFC0392B)]
              : isNearBudget
              ? [const Color(0xFFF39C12), const Color(0xFFE67E22)]
              : [const Color(0xFF27AE60), const Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOverBudget
                      ? Icons.warning_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isOverBudget
                    ? 'Over Budget!'
                    : isNearBudget
                    ? 'Almost There!'
                    : 'On Track!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _spentPercentage / 100 > 1 ? 1 : _spentPercentage / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_spentPercentage.toStringAsFixed(0)}% used',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                '${(100 - _spentPercentage).toStringAsFixed(0)}% remaining',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('Income', currencyFormat.format(_monthlyIncome)),
              const SizedBox(width: 8),
              _buildStatBox('Expenses', currencyFormat.format(_totalPlanned)),
              const SizedBox(width: 8),
              _buildStatBox(
                isOverBudget ? 'Over by' : 'Remaining',
                currencyFormat.format(_remaining.abs()),
              ),
            ],
          ),
          if (_remaining > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'You can save ${currencyFormat.format(_remaining)} this month! 💰',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isOverBudget) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try reducing some expenses to stay within budget!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
