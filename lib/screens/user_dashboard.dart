// lib/screens/user_dashboard.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calculator_screen.dart';
import 'expense_report_screen.dart';
import 'expense_screen.dart';
import 'income_report_screen.dart';
import 'income_screen.dart';
import 'login_screen.dart';
import 'password_change_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // ==================== FINANCIAL SUMMARY VARIABLES ====================
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;
  bool _isLoadingSummary = false;

  // ==================== DATE FILTER VARIABLES ====================
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFinancialSummary();
  }

  // ==================== LOAD FINANCIAL SUMMARY WITH DATE FILTER ====================
  Future<void> _loadFinancialSummary() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoadingSummary = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      Query query = firestore
          .collection('ExpensoUsers')
          .doc(currentUser.uid)
          .collection('transactions');

      // Apply date filters
      if (_fromDate != null && _toDate != null) {
        // Use custom date range
        query = query
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate!),
            )
            .where(
              'date',
              isLessThan: Timestamp.fromDate(
                _toDate!.add(const Duration(days: 1)),
              ),
            );
      } else if (_selectedMonth != null) {
        // Use selected month
        final startOfMonth = DateTime(
          _selectedMonth!.year,
          _selectedMonth!.month,
          1,
        );
        final endOfMonth = DateTime(
          _selectedMonth!.year,
          _selectedMonth!.month + 1,
          1,
        );
        query = query
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfMonth));
      } else {
        // Default: current month
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        query = query
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfMonth));
      }

      QuerySnapshot transactionSnapshot = await query.get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in transactionSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = data['type'] as String? ?? 'expense';

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = totalIncome;
          _totalExpense = totalExpense;
          _balance = totalIncome - totalExpense;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      print('❌ Error loading financial summary: $e');
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  // ==================== DATE PICKER METHODS ====================
  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select From Date',
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // If toDate is before fromDate, reset it
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
        // Clear month selection when using custom range
        _selectedMonth = null;
      });
      _loadFinancialSummary();
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select To Date',
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        // Clear month selection when using custom range
        _selectedMonth = null;
      });
      _loadFinancialSummary();
    }
  }

  void _selectQuickMonth(DateTime? month) {
    setState(() {
      _selectedMonth = month;
      // Clear custom date range
      _fromDate = null;
      _toDate = null;
    });
    _loadFinancialSummary();
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedMonth = null;
    });
    _loadFinancialSummary();
  }

  // ==================== LOAD USER DATA ====================
  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      print('📱 Dashboard - Current user: ${currentUser?.email ?? "No user"}');
      print('📱 Dashboard - User UID: ${currentUser?.uid ?? "No UID"}');

      if (currentUser != null) {
        final firestore = FirebaseFirestore.instance;

        // Check ExpensoUsers collection
        DocumentSnapshot userDoc = await firestore
            .collection('ExpensoUsers')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          print('✅ Dashboard - User data loaded successfully');

          setState(() {
            _userData = data;
            _isLoading = false;
          });
        } else {
          print('⚠️ Dashboard - User document not found in ExpensoUsers');
          setState(() => _isLoading = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User data not found. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } else {
        print('⚠️ Dashboard - No current user in FirebaseAuth');
        setState(() => _isLoading = false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ Dashboard - Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        print('❌ Logout error: $e');
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ==================== BUILD METHOD ====================
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
                'Loading your dashboard...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/dashboard.png',
              fit: BoxFit.cover,
            ),
          ),

          // Light Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _appBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),

                        // DATE FILTER SECTION
                        _buildDateFilterSection(),
                        const SizedBox(height: 12),

                        // FINANCIAL SUMMARY CARDS
                        _buildFinancialSummaryCards(),
                        const SizedBox(height: 16),

                        // Quick Actions
                        _buildSection(context, "Quick Actions", [
                          _card(context, 'Income', Icons.trending_up, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IncomeScreen(),
                              ),
                            ).then((_) => _loadFinancialSummary());
                          }),
                          _card(context, 'Expenses', Icons.trending_down, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpenseScreen(),
                              ),
                            ).then((_) => _loadFinancialSummary());
                          }),

                          _card(context, 'Reports', Icons.bar_chart, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ReportsScreen(), // 🆕 Use combined screen
                              ),
                            );
                          }),
                          _card(context, 'Calculator', Icons.bar_chart, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalculatorScreen(),
                              ),
                            ).then((_) => _loadFinancialSummary());
                          }),
                          _card(
                            context,
                            'Password',
                            Icons.lock_reset_rounded,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PasswordChangeScreen(),
                                ),
                              );
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DATE FILTER SECTION ====================
  Widget _buildDateFilterSection() {
    final dateFormat = DateFormat('dd-MM-yy');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: Column(
            children: [
              // Date Range Row
              Row(
                children: [
                  // From Date
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectFromDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _fromDate != null
                                ? const Color(0xFF6366F1).withOpacity(0.5)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _fromDate != null
                                    ? dateFormat.format(_fromDate!)
                                    : 'From',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _fromDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  fontWeight: _fromDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),

                  // To Date
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectToDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _toDate != null
                                ? const Color(0xFF6366F1).withOpacity(0.5)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _toDate != null
                                    ? dateFormat.format(_toDate!)
                                    : 'To',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _toDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  fontWeight: _toDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Quick Month Selector (Corner)
                  const SizedBox(width: 6),
                  _buildQuickMonthSelector(),

                  // Clear Button
                  if (_fromDate != null ||
                      _toDate != null ||
                      _selectedMonth != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: GestureDetector(
                        onTap: _clearDateFilter,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Active Filter Indicator
              if (_fromDate != null && _toDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_alt_rounded,
                        size: 14,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(_fromDate!)} - ${dateFormat.format(_toDate!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearDateFilter,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_selectedMonth != null && _fromDate == null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 14,
                        color: Color(0xFF27AE60),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF27AE60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearDateFilter,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== QUICK MONTH SELECTOR (CORNER POPUP) ====================
  Widget _buildQuickMonthSelector() {
    return GestureDetector(
      onTap: () {
        _showMonthPickerPopup();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedMonth != null
              ? const Color(0xFF27AE60).withOpacity(0.1)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedMonth != null
                ? const Color(0xFF27AE60).withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          size: 18,
          color: _selectedMonth != null
              ? const Color(0xFF27AE60)
              : Colors.grey.shade600,
        ),
      ),
    );
  }

  // Month Picker Popup (FIXED)
  void _showMonthPickerPopup() {
    final now = DateTime.now();
    final List<DateTime> months = [];

    // Generate last 12 months
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 80,
        200,
        MediaQuery.of(context).size.width - 20,
        300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        // Current Month option
        PopupMenuItem<String>(
          value: 'current_month',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedMonth == null && _fromDate == null
                  ? const Color(0xFF6366F1).withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.today_rounded,
                  size: 16,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                const Text(
                  'This Month',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (_selectedMonth == null && _fromDate == null) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 16, color: Color(0xFF6366F1)),
                ],
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Month list
        ...months.map((month) {
          final monthName = DateFormat('MMMM yyyy').format(month);
          final isSelected =
              _selectedMonth != null &&
              _selectedMonth!.year == month.year &&
              _selectedMonth!.month == month.month;
          final monthKey = 'month_${month.year}_${month.month}';

          return PopupMenuItem<String>(
            value: monthKey,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF27AE60).withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: isSelected ? const Color(0xFF27AE60) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF27AE60)
                          : Colors.black87,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 16, color: Color(0xFF27AE60)),
                  ],
                ],
              ),
            ),
          );
        }),
        const PopupMenuDivider(height: 1),
        // Clear filter option
        PopupMenuItem<String>(
          value: 'clear',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Row(
              children: [
                Icon(Icons.clear_all_rounded, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Clear Filter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'current_month') {
        _selectQuickMonth(null);
      } else if (value == 'clear') {
        _clearDateFilter();
      } else if (value != null && value.startsWith('month_')) {
        final parts = value.split('_');
        final year = int.parse(parts[1]);
        final month = int.parse(parts[2]);
        _selectQuickMonth(DateTime(year, month, 1));
      }
    });
  }

  // ==================== FINANCIAL SUMMARY CARDS ====================
  Widget _buildFinancialSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // Dynamic title based on filter
    String periodTitle;
    if (_fromDate != null && _toDate != null) {
      periodTitle =
          '${DateFormat('dd MMM').format(_fromDate!)} - ${DateFormat('dd MMM yyyy').format(_toDate!)}';
    } else if (_selectedMonth != null) {
      periodTitle = DateFormat('MMMM yyyy').format(_selectedMonth!);
    } else {
      periodTitle = DateFormat('MMMM yyyy').format(DateTime.now());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        // Row(
        //   children: [
        //     Container(
        //       width: 4,
        //       height: 20,
        //       decoration: BoxDecoration(
        //         gradient: const LinearGradient(
        //           colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        //         ),
        //         borderRadius: BorderRadius.circular(2),
        //       ),
        //     ),
        //     const SizedBox(width: 10),
        // Text(
        //   'Overview',
        //   style: TextStyle(
        //     fontSize: 15,
        //     fontWeight: FontWeight.w700,
        //     color: Colors.grey.shade800,
        //     letterSpacing: -0.3,
        //   ),
        // ),
        //     const Spacer(),
        //     Text(
        //       periodTitle,
        //       style: TextStyle(
        //         fontSize: 11,
        //         color: Colors.grey.shade500,
        //         fontWeight: FontWeight.w500,
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 12),

        // Summary Cards Row
        Row(
          children: [
            // Income Card
            Expanded(
              child: _buildSummaryCard(
                title: 'Income',
                amount: _totalIncome,
                icon: Icons.arrow_downward_rounded,
                gradientColors: const [Color(0xFF27AE60), Color(0xFF2ECC71)],
                isLoading: _isLoadingSummary,
              ),
            ),
            const SizedBox(width: 10),

            // Expense Card
            Expanded(
              child: _buildSummaryCard(
                title: 'Expenses',
                amount: _totalExpense,
                icon: Icons.arrow_upward_rounded,
                gradientColors: const [Color(0xFFE74C3C), Color(0xFFC0392B)],
                isLoading: _isLoadingSummary,
              ),
            ),
            const SizedBox(width: 10),

            // Balance Card
            Expanded(
              child: _buildSummaryCard(
                title: 'Balance',
                amount: _balance,
                icon: Icons.account_balance_wallet_rounded,
                gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                isLoading: _isLoadingSummary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Individual Summary Card
  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isLoading,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.75),
                Colors.white.withOpacity(0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Amount
              if (isLoading)
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gradientColors.first,
                  ),
                )
              else
                Text(
                  currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: gradientColors.first,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                // 🆕 Settings Icon (Left)
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black87,
                    size: 22,
                  ),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),

                const Spacer(),

                // Title (Center)
                const Text(
                  "EXPENSO",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // Logout Icon (Right)
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SECTION ====================
  Widget _buildSection(BuildContext context, String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: cards,
        ),
      ],
    );
  }

  // ==================== USER HEADER ====================
  // ==================== USER HEADER (UPDATED - CLICKABLE) ====================
  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) {
          // Reload user data when returning from profile
          _loadUserData();
          _loadFinancialSummary();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF6366F1),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userData?['businessName'] ??
                            _userData?['name'] ??
                            'User',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userData?['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 🆕 Add edit icon to indicate it's clickable
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== PREMIUM CARD ====================
  Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: Colors.black87),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
