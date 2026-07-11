// lib/screens/income_report_screen.dart
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class IncomeReportScreen extends StatefulWidget {
  const IncomeReportScreen({super.key});

  @override
  State<IncomeReportScreen> createState() => _IncomeReportScreenState();
}

class _IncomeReportScreenState extends State<IncomeReportScreen> {
  // ==================== VARIABLES ====================
  List<Map<String, dynamic>> _allIncomes = [];
  List<Map<String, dynamic>> _filteredIncomes = [];
  Map<String, double> _categoryWiseIncome = {};
  double _totalIncome = 0.0;
  bool _isLoading = true;

  // Date filter
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _selectedMonth;

  // Category filter
  String? _selectedCategoryFilter;
  List<String> _incomeCategories = [];

  // Expand/collapse for Top Sources
  bool _showAllTopSources = false;

  // Current user
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  // ==================== LOAD INCOME DATA ====================
  Future<void> _loadIncomeData() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      Query query = firestore
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .orderBy('date', descending: true);

      // Apply date filter
      if (_fromDate != null && _toDate != null) {
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
      }

      final snapshot = await query.get();

      final incomes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime date;
        if (data['date'] is Timestamp) {
          date = (data['date'] as Timestamp).toDate();
        } else {
          date = DateTime.now();
        }

        return {
          'id': doc.id,
          'date': date,
          'category': data['category'] ?? data['incomeType'] ?? 'Other',
          'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
          'source': data['source'] ?? '',
          'description': data['description'] ?? '',
          'paymentMethod': data['paymentMethod'] ?? '',
        };
      }).toList();

      // Extract unique categories
      final categories =
          incomes.map((i) => i['category'] as String).toSet().toList()..sort();

      // Calculate category-wise income
      Map<String, double> categoryWise = {};
      for (var income in incomes) {
        final category = income['category'] as String;
        final amount = income['amount'] as double;
        categoryWise[category] = (categoryWise[category] ?? 0) + amount;
      }

      // Apply category filter
      List<Map<String, dynamic>> filtered = incomes;
      if (_selectedCategoryFilter != null && _selectedCategoryFilter != 'All') {
        filtered = incomes
            .where((i) => i['category'] == _selectedCategoryFilter)
            .toList();
      }

      // Calculate total
      double total = filtered.fold(
        0.0,
        (sum, i) => sum + (i['amount'] as double),
      );

      if (mounted) {
        setState(() {
          _allIncomes = incomes;
          _filteredIncomes = filtered;
          _incomeCategories = ['All', ...categories];
          _categoryWiseIncome = categoryWise;
          _totalIncome = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading income data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== DATE FILTER METHODS ====================
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
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
        _selectedMonth = null;
      });
      _loadIncomeData();
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
        _selectedMonth = null;
      });
      _loadIncomeData();
    }
  }

  void _selectQuickMonth(DateTime? month) {
    setState(() {
      _selectedMonth = month;
      _fromDate = null;
      _toDate = null;
    });
    _loadIncomeData();
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedMonth = null;
    });
    _loadIncomeData();
  }

  // ==================== GET PERIOD TITLE ====================
  String _getPeriodTitle() {
    if (_fromDate != null && _toDate != null) {
      return '${DateFormat('dd MMM').format(_fromDate!)} - ${DateFormat('dd MMM yyyy').format(_toDate!)}';
    } else if (_selectedMonth != null) {
      return DateFormat('MMMM yyyy').format(_selectedMonth!);
    }
    return 'All Time';
  }

  // ==================== WORKING PDF EXPORT ====================
  Future<void> _exportToPDF() async {
    // Show loading indicator
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
            CircularProgressIndicator(color: Color(0xFF27AE60)),
            SizedBox(height: 16),
            Text(
              'Generating PDF...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
      );
      final dateFormat = DateFormat('dd-MM-yyyy');
      final reportDate = DateFormat(
        'dd MMMM yyyy, hh:mm a',
      ).format(DateTime.now());

      // Colors
      final primaryColor = PdfColor.fromInt(0xFF27AE60);
      final darkColor = PdfColor.fromInt(0xFF1E293B);
      final greyColor = PdfColor.fromInt(0xFF64748B);
      final lightGreyColor = PdfColor.fromInt(0xFFF1F5F9);
      final whiteColor = PdfColor.fromInt(0xFFFFFFFF);

      // Build category breakdown widgets list
      final sortedCategories = _categoryWiseIncome.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      List<pw.Widget> categoryWidgets = [];
      for (var entry in sortedCategories) {
        final percentage = _totalIncome > 0
            ? (entry.value / _totalIncome * 100)
            : 0.0;
        categoryWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    pw.Text(
                      currencyFormat.format(entry.value),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: lightGreyColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: (percentage / 100) * 400,
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${percentage.toStringAsFixed(1)}% (${_allIncomes.where((e) => e['category'] == entry.key).length} transactions)',
                  style: pw.TextStyle(fontSize: 9, color: greyColor),
                ),
              ],
            ),
          ),
        );
      }

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => [
            // ===== HEADER =====
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: primaryColor, width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EXPENSO',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Income Report',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: darkColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: $reportDate',
                        style: pw.TextStyle(fontSize: 9, color: greyColor),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Period: ${_getPeriodTitle()}',
                        style: pw.TextStyle(fontSize: 9, color: greyColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ===== SUMMARY SECTION =====
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF0FDF4),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFBBF7D0)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryItem(
                    'Total Income',
                    currencyFormat.format(_totalIncome),
                    primaryColor,
                  ),
                  _buildPdfSummaryItem(
                    'Transactions',
                    '${_filteredIncomes.length}',
                    darkColor,
                  ),
                  _buildPdfSummaryItem(
                    'Categories',
                    '${_categoryWiseIncome.length}',
                    darkColor,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ===== CATEGORY BREAKDOWN =====
            pw.Text(
              'Category-wise Breakdown',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 12),

            // Add all category widgets
            ...categoryWidgets,

            pw.SizedBox(height: 20),

            // ===== TRANSACTION TABLE =====
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 12),

            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: whiteColor,
              ),
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              cellStyle: pw.TextStyle(fontSize: 9, color: darkColor),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              headerPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              oddRowDecoration: pw.BoxDecoration(color: lightGreyColor),
              headers: ['#', 'Date', 'Category', 'Source', 'Amount'],
              data: _filteredIncomes.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final inc = entry.value;
                return [
                  '$i',
                  dateFormat.format(inc['date'] as DateTime),
                  inc['category'] ?? '-',
                  inc['source']?.isNotEmpty == true ? inc['source'] : '-',
                  currencyFormat.format(inc['amount'] ?? 0),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            // ===== TOTAL ROW =====
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF0FDF4),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL INCOME',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(_totalIncome),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // ===== FOOTER =====
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Expenso - Expense Tracker',
                    style: pw.TextStyle(fontSize: 9, color: greyColor),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: pw.TextStyle(fontSize: 9, color: greyColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final fileName =
          'Income_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success and open file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF saved: $fileName',
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
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );

        // Auto-open the PDF
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('❌ PDF Error: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to generate PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper for PDF summary items
  pw.Widget _buildPdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromInt(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Income Report',
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
          // PDF Export Button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 20,
                color: Color(0xFFE74C3C),
              ),
              onPressed: () => _exportToPDF(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Export PDF',
            ),
          ),
          // Refresh Button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Color(0xFF27AE60),
              ),
              onPressed: _loadIncomeData,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Income Summary Card
                  _buildSummaryCard(currencyFormat),
                  const SizedBox(height: 16),

                  // Date Filter
                  _buildDateFilterSection(),
                  const SizedBox(height: 16),

                  // Category Filter Dropdown
                  _buildCategoryDropdownFilter(currencyFormat),
                  const SizedBox(height: 16),

                  // Top Categories (with click arrow)
                  _buildTopCategories(currencyFormat),
                  const SizedBox(height: 16),

                  // Income List
                  _buildIncomeTable(currencyFormat),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==================== SUMMARY CARD ====================
  Widget _buildSummaryCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27AE60).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(_totalIncome),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryStat(
                label: 'Transactions',
                value: '${_filteredIncomes.length}',
              ),
              const SizedBox(width: 16),
              _buildSummaryStat(label: 'Period', value: _getPeriodTitle()),
              const SizedBox(width: 16),
              _buildSummaryStat(
                label: 'Categories',
                value: '${_categoryWiseIncome.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 16,
                    color: Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter by Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  if (_fromDate != null ||
                      _toDate != null ||
                      _selectedMonth != null)
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectFromDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _fromDate != null
                                ? const Color(0xFF27AE60).withOpacity(0.5)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _fromDate != null
                              ? dateFormat.format(_fromDate!)
                              : 'From',
                          style: TextStyle(
                            fontSize: 12,
                            color: _fromDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectToDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _toDate != null
                                ? const Color(0xFF27AE60).withOpacity(0.5)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _toDate != null ? dateFormat.format(_toDate!) : 'To',
                          style: TextStyle(
                            fontSize: 12,
                            color: _toDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildQuickMonthSelector(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMonthSelector() {
    return GestureDetector(
      onTap: _showMonthPickerPopup,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedMonth != null
              ? const Color(0xFF27AE60).withOpacity(0.1)
              : const Color(0xFFF8FAFC),
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
          color: _selectedMonth != null ? const Color(0xFF27AE60) : Colors.grey,
        ),
      ),
    );
  }

  void _showMonthPickerPopup() {
    final now = DateTime.now();
    final List<DateTime> months = [];
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 80,
        350,
        MediaQuery.of(context).size.width - 20,
        450,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              const Icon(
                Icons.all_inclusive,
                size: 16,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              const Text('All Time', style: TextStyle(fontSize: 13)),
              if (_selectedMonth == null && _fromDate == null) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: Color(0xFF6366F1)),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        ...months.map((month) {
          final monthName = DateFormat('MMMM yyyy').format(month);
          final isSelected =
              _selectedMonth != null &&
              _selectedMonth!.year == month.year &&
              _selectedMonth!.month == month.month;
          final monthKey = 'month_${month.year}_${month.month}';

          return PopupMenuItem<String>(
            value: monthKey,
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
          );
        }),
      ],
    ).then((value) {
      if (value == 'all') {
        _clearDateFilter();
      } else if (value != null && value.startsWith('month_')) {
        final parts = value.split('_');
        _selectQuickMonth(
          DateTime(int.parse(parts[1]), int.parse(parts[2]), 1),
        );
      }
    });
  }

  // ==================== CATEGORY DROPDOWN FILTER ====================
  Widget _buildCategoryDropdownFilter(NumberFormat currencyFormat) {
    if (_incomeCategories.length <= 1) return const SizedBox();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCategoryFilter != null &&
                      _selectedCategoryFilter != 'All')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_filteredIncomes.length} results',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF27AE60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategoryFilter ?? 'All',
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                    items: _incomeCategories.map((category) {
                      final count = category == 'All'
                          ? _allIncomes.length
                          : _allIncomes
                                .where((i) => i['category'] == category)
                                .length;
                      final amount = category == 'All'
                          ? _allIncomes.fold(
                              0.0,
                              (sum, i) => sum + (i['amount'] as double),
                            )
                          : _allIncomes
                                .where((i) => i['category'] == category)
                                .fold(
                                  0.0,
                                  (sum, i) => sum + (i['amount'] as double),
                                );

                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: category == 'All'
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF27AE60),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      category == _selectedCategoryFilter ||
                                          (category == 'All' &&
                                              _selectedCategoryFilter == null)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Text(
                              '$count | ${currencyFormat.format(amount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryFilter = value == 'All' ? null : value;
                        _showAllTopSources = false;
                      });
                      _loadIncomeData();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TOP CATEGORIES (COLLAPSIBLE) ====================
  Widget _buildTopCategories(NumberFormat currencyFormat) {
    List<MapEntry<String, double>> sorted;
    if (_selectedCategoryFilter != null && _selectedCategoryFilter != 'All') {
      sorted = _categoryWiseIncome.entries
          .where((e) => e.key == _selectedCategoryFilter)
          .toList();
    } else {
      sorted = _categoryWiseIncome.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }

    if (sorted.isEmpty) return const SizedBox();

    final totalForCalculation =
        _selectedCategoryFilter != null && _selectedCategoryFilter != 'All'
        ? sorted.first.value
        : _allIncomes.fold(0.0, (sum, i) => sum + (i['amount'] as double));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Header
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllTopSources = !_showAllTopSources;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Top Income Sources',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedRotation(
                          turns: _showAllTopSources ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: Color(0xFFF39C12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Content
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0, width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: sorted.map((entry) {
                      final percentage = totalForCalculation > 0
                          ? (entry.value / totalForCalculation * 100)
                          : 0.0;
                      final transactionCount = _allIncomes
                          .where((i) => i['category'] == entry.key)
                          .length;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currencyFormat.format(entry.value),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF27AE60),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: const Color(0xFF27AE60),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of income',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  '$transactionCount transactions',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                crossFadeState: _showAllTopSources
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 350),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== INCOME TABLE ====================
  Widget _buildIncomeTable(NumberFormat currencyFormat) {
    final dateFormat = DateFormat('dd-MM-yy');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF27AE60),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
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
                        'Category',
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
                  ],
                ),
              ),

              // Table Body
              if (_filteredIncomes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No income records found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredIncomes.take(15).toList().asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final income = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: index % 2 == 0
                          ? Colors.white
                          : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            dateFormat.format(income['date'] as DateTime),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            income['category'] ?? '-',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            income['source']?.isNotEmpty == true
                                ? income['source']
                                : '-',
                            style: TextStyle(
                              fontSize: 11,
                              color: income['source']?.isNotEmpty == true
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
                            '+ ${currencyFormat.format(income['amount'])}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF27AE60),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // Total Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_totalIncome),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredIncomes.length} transactions',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_filteredIncomes.length > 15)
                      Text(
                        ' (Showing 15)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
