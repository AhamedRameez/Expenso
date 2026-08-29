// lib/screens/credit_detail_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'credit_edit_screen.dart';

class CreditDetailScreen extends StatefulWidget {
  final Map<String, dynamic> credit;

  const CreditDetailScreen({super.key, required this.credit});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _currentUserId;
  late Map<String, dynamic> _credit;
  DateTime _paymentDate = DateTime.now();
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _credit = Map<String, dynamic>.from(widget.credit);
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ==================== LOAD PAYMENT HISTORY ====================
  Future<void> _loadPaymentHistory() async {
    if (_currentUserId == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .collection('payments')
          .orderBy('date', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _paymentHistory = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading payment history: $e');
    }
  }

  Future<void> _reloadCredit() async {
    final doc = await FirebaseFirestore.instance
        .collection('ExpensoUsers')
        .doc(_currentUserId)
        .collection('credits')
        .doc(_credit['id'])
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _credit = {'id': doc.id, ...doc.data()!};
      });
      _loadPaymentHistory();
    }
  }

  Future<void> _markAsFullyPaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF27AE60)),
            SizedBox(width: 8),
            Text('Mark Fully Paid?'),
          ],
        ),
        content: const Text(
          'This will mark the entire amount as received and move it to the cleared section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final totalAmount = (_credit['amount'] as num).toDouble();
    final alreadyPaid = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
    final remainingAmount = totalAmount - alreadyPaid;
    try {
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .collection('payments')
          .add({
            'amount': remainingAmount,
            'date': Timestamp.fromDate(DateTime.now()),
            'type': 'full',
          });
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .update({'status': 'paid', 'paidAmount': totalAmount});
      setState(() {
        _credit['status'] = 'paid';
        _credit['paidAmount'] = totalAmount;
      });
      _loadPaymentHistory();
      _showSnackBar('Marked as fully paid! ✓', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showAddPaymentDialog() {
    final totalAmount = (_credit['amount'] as num).toDouble();
    final alreadyPaid = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
    final remaining = totalAmount - alreadyPaid;
    _amountController.clear();
    _paymentDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Remaining: ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '₹${NumberFormat('#,###').format(remaining)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF39C12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () =>
                    _amountController.text = remaining.toStringAsFixed(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap to fill full amount',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount Received',
                  hintText: 'Enter amount',
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
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null)
                    setDialogState(() => _paymentDate = picked);
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
                        DateFormat('dd-MM-yyyy').format(_paymentDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Auto-saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF27AE60),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0 || amount > remaining) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Enter valid amount (max: ₹${NumberFormat('#,###').format(remaining)})',
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final newPaidAmount = alreadyPaid + amount;
                final newStatus = newPaidAmount >= totalAmount
                    ? 'paid'
                    : 'partial';
                Navigator.pop(dialogContext);
                showDialog(
                  context: this.context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  await FirebaseFirestore.instance
                      .collection('ExpensoUsers')
                      .doc(_currentUserId)
                      .collection('credits')
                      .doc(_credit['id'])
                      .collection('payments')
                      .add({
                        'amount': amount,
                        'date': Timestamp.fromDate(_paymentDate),
                        'type': newStatus == 'paid' ? 'full' : 'partial',
                      });
                  await FirebaseFirestore.instance
                      .collection('ExpensoUsers')
                      .doc(_currentUserId)
                      .collection('credits')
                      .doc(_credit['id'])
                      .update({
                        'paidAmount': newPaidAmount,
                        'status': newStatus,
                      });
                  setState(() {
                    _credit['paidAmount'] = newPaidAmount;
                    _credit['status'] = newStatus;
                  });
                  if (mounted) {
                    Navigator.pop(this.context);
                    _loadPaymentHistory();
                    _showSnackBar(
                      newStatus == 'paid'
                          ? 'Fully paid! ✓'
                          : '₹${NumberFormat('#,###').format(amount)} added!',
                      Colors.green,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(this.context);
                    _showSnackBar('Error: $e', Colors.red);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCredit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Credit'),
          ],
        ),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final payments = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .collection('payments')
          .get();
      for (var doc in payments.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .doc(_credit['id'])
          .delete();
      if (mounted) {
        _showSnackBar('Deleted!', Colors.green);
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _exportPaymentHistoryPDF() async {
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
            CircularProgressIndicator(color: Color(0xFF6366F1)),
            SizedBox(height: 16),
            Text(
              'Generating PDF...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    try {
      final pdf = pw.Document();
      final cf = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
      final df = DateFormat('dd-MM-yyyy');
      final rd = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());
      final name = _credit['personName'] as String? ?? 'Unknown';
      final purpose = _credit['purpose'] as String? ?? '';
      final totalAmount = (_credit['amount'] as num?)?.toDouble() ?? 0;
      final paidAmount = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
      final remaining = totalAmount - paidAmount;
      final status = _credit['status'] as String? ?? 'pending';
      final dateGiven = _credit['dateGiven'] as Timestamp?;
      final expectedDate = _credit['expectedDate'] as Timestamp?;
      final contact = _credit['contact'] as String? ?? '';
      final pc = PdfColor.fromInt(0xFF6366F1),
          dc = PdfColor.fromInt(0xFF1E293B),
          gc = PdfColor.fromInt(0xFF64748B),
          lgc = PdfColor.fromInt(0xFFF1F5F9),
          wc = PdfColor.fromInt(0xFFFFFFFF),
          grc = PdfColor.fromInt(0xFF27AE60),
          rc = PdfColor.fromInt(0xFFE74C3C);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: pc, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IN EXPENSO',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: pc,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Credit Payment Report',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: dc,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: $rd',
                        style: pw.TextStyle(fontSize: 9, color: gc),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: lgc,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Credit Details',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: dc,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _pdfRow('Person/Business', name, dc),
                  if (purpose.isNotEmpty) _pdfRow('Purpose', purpose, dc),
                  if (contact.isNotEmpty) _pdfRow('Contact', contact, dc),
                  _pdfRow(
                    'Date Given',
                    dateGiven != null ? df.format(dateGiven.toDate()) : '-',
                    dc,
                  ),
                  if (expectedDate != null)
                    _pdfRow(
                      'Expected Return',
                      df.format(expectedDate.toDate()),
                      dc,
                    ),
                  pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
                  _pdfRow('Total Amount', cf.format(totalAmount), dc),
                  _pdfRow('Amount Received', cf.format(paidAmount), grc),
                  _pdfRow(
                    'Remaining',
                    cf.format(remaining),
                    remaining > 0 ? rc : grc,
                  ),
                  _pdfRow(
                    'Status',
                    status == 'paid'
                        ? 'Cleared'
                        : status == 'partial'
                        ? 'Partially Paid'
                        : 'Pending',
                    status == 'paid' ? grc : rc,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            if (_paymentHistory.isNotEmpty) ...[
              pw.Text(
                'Payment History',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: dc,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: wc,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: pc,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                cellStyle: pw.TextStyle(fontSize: 10, color: dc),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                headerPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                oddRowDecoration: pw.BoxDecoration(color: lgc),
                headers: ['#', 'Date', 'Amount', 'Type'],
                data: _paymentHistory.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final p = e.value;
                  final pa = (p['amount'] as num?)?.toDouble() ?? 0;
                  final pd = p['date'] as Timestamp?;
                  final pt = p['type'] as String? ?? 'partial';
                  String tt = pt == 'full'
                      ? 'Full Payment'
                      : pt == 'added_money'
                      ? 'Added More Money'
                      : 'Partial';
                  return [
                    '$i',
                    pd != null ? df.format(pd.toDate()) : '-',
                    cf.format(pa),
                    tt,
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lgc,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Payments',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: dc,
                      ),
                    ),
                    pw.Text(
                      '${_paymentHistory.length} entries',
                      style: pw.TextStyle(fontSize: 11, color: gc),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'In Expenso - Credit Report',
                    style: pw.TextStyle(fontSize: 9, color: gc),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: pw.TextStyle(fontSize: 9, color: gc),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName =
          'Credit_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      if (mounted) Navigator.pop(context);
      try {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        if (mounted) _showSnackBar('PDF downloaded!', Colors.green);
      } catch (_) {
        try {
          final output = await getTemporaryDirectory();
          final file = File('${output.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
          if (mounted) {
            _showSnackBar('PDF saved!', Colors.green);
            await OpenFile.open(file.path);
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed: $e', Colors.red);
      }
    }
  }

  pw.Widget _pdfRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
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

  Future<void> _contactPerson(String contact) async {
    if (contact.contains('@')) {
      await launchUrl(Uri.parse('mailto:$contact'));
    } else {
      await launchUrl(Uri.parse('tel:$contact'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMMM yyyy');
    final name = _credit['personName'] as String? ?? 'Unknown';
    final purpose = _credit['purpose'] as String? ?? '';
    final amount = (_credit['amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (_credit['paidAmount'] as num?)?.toDouble() ?? 0;
    final remaining = amount - paidAmount;
    final status = _credit['status'] as String? ?? 'pending';
    final contact = _credit['contact'] as String? ?? '';
    final notes = _credit['notes'] as String? ?? '';
    final dateGiven = _credit['dateGiven'] as Timestamp?;
    final expectedDate = _credit['expectedDate'] as Timestamp?;
    final isOverdue =
        status != 'paid' &&
        expectedDate != null &&
        expectedDate.toDate().isBefore(DateTime.now());

    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (status == 'paid') {
      statusColor = const Color(0xFF27AE60);
      statusText = 'Cleared ✓';
      statusIcon = Icons.check_circle;
    } else if (status == 'partial') {
      statusColor = const Color(0xFFF39C12);
      statusText = 'Partially Paid';
      statusIcon = Icons.money;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue!';
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
      statusIcon = Icons.pending;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Credit Details',
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
              Icons.edit_outlined,
              size: 22,
              color: Color(0xFF6366F1),
            ),
            tooltip: 'Edit Credit',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreditEditScreen(credit: _credit),
                ),
              );
              if (result == true) _reloadCredit();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 22,
              color: Color(0xFFE74C3C),
            ),
            tooltip: 'Export PDF',
            onPressed: _exportPaymentHistoryPDF,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            tooltip: 'Delete',
            onPressed: _deleteCredit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎨 Professional full-width rectangular status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: status == 'paid' ? const Color(0xFF27AE60) : statusColor,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: Icon + Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Right side: Amount + Subtitle (right-aligned)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(
                          status == 'paid' ? amount : remaining,
                        ),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      if (status != 'paid') ...[
                        const SizedBox(height: 2),
                        Text(
                          'of ${currencyFormat.format(amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (paidAmount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Received: ${currencyFormat.format(paidAmount)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Rest of the content with padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (status != 'paid') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddPaymentDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _markAsFullyPaid,
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text('Mark Fully Paid'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF27AE60),
                              side: const BorderSide(color: Color(0xFF27AE60)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_paymentHistory.isNotEmpty) ...[
                    _sectionTitle('Payment History', Icons.history),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.03),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        children: _paymentHistory.map((payment) {
                          final pAmount =
                              (payment['amount'] as num?)?.toDouble() ?? 0;
                          final pDate = payment['date'] as Timestamp?;
                          final pType = payment['type'] as String? ?? 'partial';
                          final isAddedMoney = pType == 'added_money';
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isAddedMoney
                                    ? const Color(0xFF6366F1).withOpacity(0.1)
                                    : const Color(0xFF27AE60).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isAddedMoney ? Icons.add_circle : Icons.check,
                                color: isAddedMoney
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF27AE60),
                                size: 16,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  '+ ${currencyFormat.format(pAmount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isAddedMoney) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Added More',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              pDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(pDate.toDate())
                                  : '',
                            ),
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.03),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.person, 'Name', name),
                        if (purpose.isNotEmpty) ...[
                          const Divider(height: 16),
                          _detailRow(
                            Icons.description_outlined,
                            'Purpose',
                            purpose,
                          ),
                        ],
                        if (contact.isNotEmpty) ...[
                          const Divider(height: 16),
                          _detailRow(
                            Icons.contact_phone_outlined,
                            'Contact',
                            contact,
                            trailing: GestureDetector(
                              onTap: () => _contactPerson(contact),
                              child: const Icon(
                                Icons.call,
                                size: 18,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 16),
                        _detailRow(
                          Icons.calendar_today,
                          'Given',
                          dateGiven != null
                              ? dateFormat.format(dateGiven.toDate())
                              : '-',
                        ),
                        if (expectedDate != null) ...[
                          const Divider(height: 16),
                          _detailRow(
                            Icons.event,
                            'Expected Return',
                            dateFormat.format(expectedDate.toDate()),
                            valueColor: isOverdue ? Colors.red : null,
                          ),
                        ],
                        if (notes.isNotEmpty) ...[
                          const Divider(height: 16),
                          _detailRow(Icons.note_outlined, 'Notes', notes),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (amount > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: paidAmount / amount,
                        backgroundColor: Colors.grey.shade200,
                        color: status == 'paid'
                            ? const Color(0xFF27AE60)
                            : const Color(0xFF6366F1),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((paidAmount / amount) * 100).toStringAsFixed(0)}% recovered',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
