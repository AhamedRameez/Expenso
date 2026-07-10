// lib/screens/income_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  // ==================== CONTROLLERS ====================
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _newIncomeTypeController =
      TextEditingController();

  // Selected values
  DateTime _selectedDate = DateTime.now();
  String? _selectedIncomeType;
  String _selectedPaymentMethod = 'Bank Transfer';

  // Month filter
  DateTime _selectedMonth = DateTime.now();
  String? _selectedMonthFilter;

  // Dynamic income types list
  List<String> _incomeTypes = [];
  bool _isLoadingTypes = false;

  // Payment methods
  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Cheque',
    'Card',
    'Other',
  ];

  // Income list
  List<Map<String, dynamic>> _incomes = [];
  bool _isLoading = false;

  // Current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Available months for filter (last 12 months)
  List<DateTime> _availableMonths = [];

  // Financial summary values
  double _totalIncome = 0;
  double _totalExpenseAll = 0;
  double _netBalance = 0;
  bool _isLoadingFinancialSummary = false;

  // Financial summary date range
  DateTime? _summaryFromDate;
  DateTime? _summaryToDate;

  @override
  void initState() {
    super.initState();
    _generateAvailableMonths();
    _fetchIncomeTypes();
    _fetchIncomes();
    _fetchFinancialSummary();
  }

  // ==================== FETCH FINANCIAL SUMMARY ====================
  Future<void> _fetchFinancialSummary() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoadingFinancialSummary = true;
    });

    try {
      Query transactionQuery = FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions');

      if (_summaryFromDate != null && _summaryToDate != null) {
        final startTimestamp = Timestamp.fromDate(_summaryFromDate!);
        final endTimestamp = Timestamp.fromDate(
          _summaryToDate!.add(const Duration(days: 1)),
        );

        transactionQuery = transactionQuery
            .where('date', isGreaterThanOrEqualTo: startTimestamp)
            .where('date', isLessThan: endTimestamp);
      }

      final snapshot = await transactionQuery.get();

      double totalIncome = 0;
      double totalExpense = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? 'expense';

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      setState(() {
        _totalIncome = totalIncome;
        _totalExpenseAll = totalExpense;
        _netBalance = totalIncome - totalExpense;
      });
    } catch (e) {
      print('Error fetching financial summary: $e');
    } finally {
      setState(() {
        _isLoadingFinancialSummary = false;
      });
    }
  }

  // ==================== SUMMARY DATE SELECTION ====================
  Future<void> _selectSummaryFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _summaryFromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _summaryFromDate = picked;
        if (_summaryToDate != null &&
            _summaryFromDate!.isAfter(_summaryToDate!)) {
          _summaryToDate = null;
        }
      });
      _fetchFinancialSummary();
    }
  }

  Future<void> _selectSummaryToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _summaryToDate ?? DateTime.now(),
      firstDate: _summaryFromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _summaryToDate = picked;
      });
      _fetchFinancialSummary();
    }
  }

  void _clearSummaryDateFilter() {
    setState(() {
      _summaryFromDate = null;
      _summaryToDate = null;
    });
    _fetchFinancialSummary();
  }

  // ==================== GENERATE AVAILABLE MONTHS ====================
  void _generateAvailableMonths() {
    _availableMonths.clear();
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      _availableMonths.add(monthDate);
    }

    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedMonthFilter = _formatMonthYear(_selectedMonth);
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // ==================== FETCH INCOME TYPES ====================
  Future<void> _fetchIncomeTypes() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoadingTypes = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('incomeTypes')
          .orderBy('name')
          .get();

      final types = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] as String;
      }).toList();

      setState(() {
        _incomeTypes = types;
        if (_incomeTypes.isNotEmpty && _selectedIncomeType == null) {
          _selectedIncomeType = _incomeTypes.first;
        }
      });
    } catch (e) {
      print('Error fetching income types: $e');
    } finally {
      setState(() {
        _isLoadingTypes = false;
      });
    }
  }

  // ==================== ADD NEW INCOME TYPE ====================
  Future<void> _addNewIncomeType() async {
    final newType = _newIncomeTypeController.text.trim();

    if (newType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter income type name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_incomeTypes.contains(newType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income type already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingTypes = true;
    });

    try {
      final typeId = 'IT_${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('incomeTypes')
          .doc(typeId)
          .set({
            'name': newType,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': _currentUserId,
          });

      await _fetchIncomeTypes();

      setState(() {
        _selectedIncomeType = newType;
      });

      _newIncomeTypeController.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Income type "$newType" added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingTypes = false;
      });
    }
  }

  void _showAddIncomeTypeDialog() {
    _newIncomeTypeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Income Type'),
        content: TextField(
          controller: _newIncomeTypeController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter income type name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addNewIncomeType,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ==================== DELETE INCOME TYPE ====================
  Future<void> _deleteIncomeType(String typeName) async {
    final hasIncomes = _incomes.any(
      (income) => income['incomeType'] == typeName,
    );

    if (hasIncomes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "$typeName" - It is used in existing incomes',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income Type'),
        content: Text('Are you sure you want to delete "$typeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final snapshot = await FirebaseFirestore.instance
                  .collection('ExpensoUsers')
                  .doc(_currentUserId)
                  .collection('incomeTypes')
                  .where('name', isEqualTo: typeName)
                  .get();

              for (var doc in snapshot.docs) {
                await doc.reference.delete();
              }

              await _fetchIncomeTypes();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Income type "$typeName" deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==================== FETCH ALL INCOMES ====================
  Future<void> _fetchAllIncomes() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .orderBy('date', descending: true);

      final snapshot = await query.get();

      final incomes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        String formattedDate = '';
        if (data['date'] is Timestamp) {
          formattedDate = DateFormat(
            'dd-MM-yy',
          ).format((data['date'] as Timestamp).toDate());
        }

        return {
          'id': doc.id,
          'date': formattedDate,
          'incomeType': data['category'] ?? data['incomeType'] ?? '',
          'amount': data['amount'] ?? 0,
          'source': data['source'] ?? '',
          'description': data['description'] ?? '',
          'paymentMethod': data['paymentMethod'] ?? '',
        };
      }).toList();
      setState(() {
        _incomes = incomes;
      });
    } catch (e) {
      print('Error fetching all incomes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== FETCH INCOMES WITH MONTH FILTER ====================
  Future<void> _fetchIncomes() async {
    if (_currentUserId == null) return;

    final isAllSelected =
        _selectedMonth.year == 2000 &&
        _selectedMonth.month == 1 &&
        _selectedMonth.day == 1;
    if (isAllSelected) {
      _fetchAllIncomes();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .orderBy('date', descending: true);

      final startOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );
      final endOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );

      query = query
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth));

      final snapshot = await query.get();

      final incomes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        String formattedDate = '';
        if (data['date'] is Timestamp) {
          formattedDate = DateFormat(
            'dd-MM-yy',
          ).format((data['date'] as Timestamp).toDate());
        }

        return {
          'id': doc.id,
          'date': formattedDate,
          'incomeType': data['category'] ?? data['incomeType'] ?? '',
          'amount': data['amount'] ?? 0,
          'source': data['source'] ?? '',
          'description': data['description'] ?? '',
          'paymentMethod': data['paymentMethod'] ?? '',
        };
      }).toList();
      setState(() {
        _incomes = incomes;
      });
    } catch (e) {
      print('Error fetching incomes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== ADD INCOME ====================
  Future<void> _addIncome() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedIncomeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an income type!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionId = 'TRN_${DateTime.now().millisecondsSinceEpoch}';

      Map<String, dynamic> transactionData = {
        'transactionId': transactionId,
        'type': 'income',
        'date': Timestamp.fromDate(_selectedDate),
        'category': _selectedIncomeType,
        'incomeType': _selectedIncomeType,
        'amount': amount,
        'source': _sourceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _currentUserId,
      };

      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .doc(transactionId)
          .set(transactionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
      _fetchIncomes();
      _fetchFinancialSummary();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== DELETE INCOME ====================
  Future<void> _deleteIncome(String incomeId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this income?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('ExpensoUsers')
                  .doc(_currentUserId)
                  .collection('transactions')
                  .doc(incomeId)
                  .delete();
              _fetchIncomes();
              _fetchFinancialSummary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Income deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // ==================== CLEAR FORM ====================
  void _clearForm() {
    _amountController.clear();
    _sourceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedPaymentMethod = 'Bank Transfer';
    });
  }

  // ==================== SELECT DATE ====================
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ==================== CHANGE MONTH FILTER ====================
  void _changeMonthFilter(DateTime? newMonth) {
    if (newMonth != null) {
      setState(() {
        _selectedMonth = newMonth;
        _selectedMonthFilter = _formatMonthYear(_selectedMonth);
      });
      _fetchIncomes();
    }
  }

  // ==================== CALCULATE TOTAL ====================
  double get _totalIncomes {
    return _incomes.fold(
      0,
      (sum, income) => sum + (income['amount'] as num).toDouble(),
    );
  }

  // ==================== SHOW ALL INCOMES DIALOG ====================
  void _showAllIncomesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF27AE60),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All Incomes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${_incomes.length} entries • Total: ₹${NumberFormat('#,###').format(_totalIncomes)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Incomes List
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _incomes.length,
                    itemBuilder: (context, index) {
                      final income = _incomes[index];
                      final amount = (income['amount'] as num).toDouble();
                      final incomeId = income['id'];
                      final incomeType = income['incomeType'] ?? '-';
                      final source = income['source'] ?? '';
                      final description = income['description'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF27AE60).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF27AE60),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          incomeType,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '+ ₹${NumberFormat('#,###').format(amount)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF27AE60),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        income['date'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      if (source.isNotEmpty) ...[
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.person_outline,
                                          size: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            source,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _deleteIncome(incomeId);
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Income Management',
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
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              _fetchIncomeTypes();
              _fetchIncomes();
              _fetchFinancialSummary();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFinancialSummaryCards(context),
            _buildFormSection(context),
            _buildMonthFilter(context),
            _buildTotalAmountCard(context),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _incomes.isEmpty
                ? _buildEmptyState(context)
                : _buildIncomesTable(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================== FINANCIAL SUMMARY CARDS ====================
  Widget _buildFinancialSummaryCards(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Range Filter
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 18,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Summary Period:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectSummaryFromDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _summaryFromDate != null
                            ? DateFormat('dd-MM-yy').format(_summaryFromDate!)
                            : 'From',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const Text(' - ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectSummaryToDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _summaryToDate != null
                            ? DateFormat('dd-MM-yy').format(_summaryToDate!)
                            : 'To',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
                if (_summaryFromDate != null || _summaryToDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: _clearSummaryDateFilter,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Income',
                  amount: _totalIncome,
                  icon: Icons.arrow_downward,
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Expenses',
                  amount: _totalExpenseAll,
                  icon: Icons.arrow_upward,
                  color: const Color(0xFFE74C3C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Balance',
                  amount: _netBalance,
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF3498DB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOTAL AMOUNT CARD ====================
  Widget _buildTotalAmountCard(BuildContext context) {
    final isAllSelected =
        _selectedMonth.year == 2000 &&
        _selectedMonth.month == 1 &&
        _selectedMonth.day == 1;
    final titleText = isAllSelected
        ? 'Total Income (All Time)'
        : 'Total Income for ${_formatMonthYear(_selectedMonth)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.currency_rupee,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${NumberFormat('#,###').format(_totalIncomes)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${_incomes.length} entries',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MONTH FILTER SECTION ====================
  Widget _buildMonthFilter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, size: 18, color: Color(0xFF27AE60)),
          const SizedBox(width: 8),
          const Text(
            'Filter by Month:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<DateTime>(
                value: _selectedMonth,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Select Month'),
                items: [
                  DropdownMenuItem<DateTime>(
                    value: DateTime(2000, 1, 1),
                    child: const Text(
                      'All',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const DropdownMenuItem<DateTime>(
                    value: null,
                    enabled: false,
                    child: Divider(),
                  ),
                  ..._availableMonths.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(_formatMonthYear(month)),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value != null) {
                    if (value.year == 2000 &&
                        value.month == 1 &&
                        value.day == 1) {
                      setState(() {
                        _selectedMonth = value;
                        _selectedMonthFilter = 'All';
                      });
                      _fetchAllIncomes();
                    } else {
                      _changeMonthFilter(value);
                    }
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              final now = DateTime.now();
              _changeMonthFilter(DateTime(now.year, now.month, 1));
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ==================== FORM SECTION ====================
  Widget _buildFormSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ADD INCOME',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (_selectedMonth.year == 2000 &&
                          _selectedMonth.month == 1 &&
                          _selectedMonth.day == 1)
                      ? 'All Time'
                      : _formatMonthYear(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27AE60),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDateField(context)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _amountController,
                  label: 'Amount',
                  hint: 'Enter amount',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildIncomeTypeField(context)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Payment',
                  value: _selectedPaymentMethod,
                  items: _paymentMethods,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _sourceController,
            label: 'Source / Payer',
            hint: 'Who paid? (Company, Client, Person)',
            icon: Icons.person_outline,
            context: context,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Enter description',
            icon: Icons.description,
            context: context,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Add Income'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearForm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF27AE60),
                    side: const BorderSide(color: Color(0xFF27AE60)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== INCOME TYPE FIELD ====================
  Widget _buildIncomeTypeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Income Type',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedIncomeType,
            isExpanded: true,
            hint: const Text('Select'),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            items: [
              ..._incomeTypes.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Expanded(child: Text(item)),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteIncomeType(item),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const DropdownMenuItem(
                value: null,
                enabled: false,
                child: Divider(),
              ),
              DropdownMenuItem(
                value: '__add_new__',
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 14,
                      color: Color(0xFF27AE60),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Add New',
                      style: TextStyle(fontSize: 12, color: Color(0xFF27AE60)),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value == '__add_new__') {
                _showAddIncomeTypeDialog();
              } else if (value != null) {
                setState(() {
                  _selectedIncomeType = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // ==================== INCOMES TABLE ====================
  Widget _buildIncomesTable(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF27AE60),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Income Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Source',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // Table Body
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _incomes.length > 10 ? 10 : _incomes.length,
            itemBuilder: (context, index) {
              final income = _incomes[index];
              final amount = (income['amount'] as num).toDouble();
              final incomeId = income['id'];
              final incomeType = income['incomeType'] ?? '-';
              final source = income['source'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        income['date'] ?? 'N/A',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        incomeType,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        source.isNotEmpty ? source : '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: source.isNotEmpty
                              ? Colors.black87
                              : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '+₹${NumberFormat('#,###').format(amount)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteIncome(incomeId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Total Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text(
                  'Total: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  '₹${NumberFormat('#,###').format(_totalIncomes)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF27AE60),
                  ),
                ),
                const Spacer(),
                if (_incomes.length > 10) ...[
                  Text(
                    'Showing last 10 of ${_incomes.length}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showAllIncomesDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF27AE60).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(BuildContext context) {
    final isAllSelected =
        _selectedMonth.year == 2000 &&
        _selectedMonth.month == 1 &&
        _selectedMonth.day == 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No Income Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAllSelected
                ? 'No income recorded'
                : 'No income recorded for ${_formatMonthYear(_selectedMonth)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd-MM-yy').format(_selectedDate),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF27AE60)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF27AE60)),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _descriptionController.dispose();
    _newIncomeTypeController.dispose();
    super.dispose();
  }
}
