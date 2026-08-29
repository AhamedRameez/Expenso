// lib/screens/credit_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_credit_screen.dart';
import 'credit_detail_screen.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  List<Map<String, dynamic>> _credits = [];
  List<Map<String, dynamic>> _filteredCredits = [];
  double _totalOutstanding = 0.0;
  int _pendingCount = 0;
  int _overdueCount = 0;
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('credits')
          .orderBy('dateGiven', descending: true)
          .get();

      final credits = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      _applyFilter(credits);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(List<Map<String, dynamic>> credits) {
    double total = 0;
    int pending = 0;
    int overdue = 0;
    final now = DateTime.now();

    // Apply type filter first
    List<Map<String, dynamic>> filtered = credits;
    if (_selectedType != 'All') {
      filtered = credits
          .where((c) => c['creditType'] == _selectedType)
          .toList();
    }

    // Then apply status filter
    if (_selectedFilter == 'Pending') {
      filtered = filtered.where((c) => c['status'] == 'pending').toList();
    } else if (_selectedFilter == 'Paid') {
      filtered = filtered.where((c) => c['status'] == 'paid').toList();
    } else if (_selectedFilter == 'Overdue') {
      filtered = filtered.where((c) {
        if (c['status'] == 'paid') return false;
        if (c['expectedDate'] == null) return false;
        return (c['expectedDate'] as Timestamp).toDate().isBefore(now);
      }).toList();
    }

    // Calculate summary from ALL credits
    for (var c in credits) {
      final amount = (c['amount'] as num?)?.toDouble() ?? 0;
      final paid = (c['paidAmount'] as num?)?.toDouble() ?? 0;
      if (c['status'] != 'paid') {
        total += (amount - paid);
        pending++;
      }
      if (c['status'] != 'paid' && c['expectedDate'] != null) {
        if ((c['expectedDate'] as Timestamp).toDate().isBefore(now)) overdue++;
      }
    }

    if (mounted) {
      setState(() {
        _credits = credits;
        _filteredCredits = filtered;
        _totalOutstanding = total;
        _pendingCount = pending;
        _overdueCount = overdue;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToDetail(Map<String, dynamic> credit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreditDetailScreen(credit: credit)),
    );
    _loadCredits();
  }

  Future<void> _navigateToAddCredit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCreditScreen()),
    );
    if (result == true) _loadCredits();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Money Owed to Me',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCredit,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem(
                        'Outstanding',
                        currencyFormat.format(_totalOutstanding),
                      ),
                      Container(width: 1, height: 30, color: Colors.white30),
                      _summaryItem('Pending', '$_pendingCount'),
                      Container(width: 1, height: 30, color: Colors.white30),
                      _summaryItem(
                        'Overdue',
                        '$_overdueCount',
                        isOverdue: true,
                      ),
                    ],
                  ),
                ),

                // 🎨 Type Selector Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTypeChip('All', '📋'),
                      _buildTypeChip('Personal', '👤'),
                      _buildTypeChip('Business', '💼'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'Pending', 'Paid', 'Overdue'].map((
                      filter,
                    ) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedFilter = filter);
                            _applyFilter(_credits);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Credits List
                Expanded(
                  child: _filteredCredits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 50,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No credits found',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCredits.length,
                          itemBuilder: (context, index) => _buildCreditTile(
                            _filteredCredits[index],
                            currencyFormat,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // ==================== TYPE CHIP ====================
  Widget _buildTypeChip(String type, String emoji) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedType = type);
          _applyFilter(_credits);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: TextStyle(fontSize: isSelected ? 16 : 14)),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SUMMARY ITEM ====================
  Widget _summaryItem(String label, String value, {bool isOverdue = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.orange.shade200 : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  // ==================== CREDIT TILE ====================
  Widget _buildCreditTile(Map<String, dynamic> credit, NumberFormat cf) {
    final name = credit['personName'] as String? ?? 'Unknown';
    final amount = (credit['amount'] as num?)?.toDouble() ?? 0;
    final status = credit['status'] as String? ?? 'pending';
    final creditType = credit['creditType'] as String? ?? 'Personal';
    final dateGiven = credit['dateGiven'] as Timestamp?;
    final expectedDate = credit['expectedDate'] as Timestamp?;
    final isOverdue =
        status != 'paid' &&
        expectedDate != null &&
        expectedDate.toDate().isBefore(DateTime.now());

    Color statusColor;
    String statusText;
    if (status == 'paid') {
      statusColor = const Color(0xFF27AE60);
      statusText = 'Paid';
    } else if (status == 'partial') {
      statusColor = const Color(0xFFF39C12);
      statusText = 'Partial';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(credit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue ? Colors.red.shade100 : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: creditType == 'Business'
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : const Color(0xFFF39C12).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          creditType == 'Business' ? '💼 Biz' : '👤 Per',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: creditType == 'Business'
                                ? const Color(0xFF6366F1)
                                : const Color(0xFFF39C12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        cf.format(amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateGiven != null
                            ? DateFormat('dd MMM yy').format(dateGiven.toDate())
                            : '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (expectedDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.event,
                          size: 11,
                          color: isOverdue ? Colors.red : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due ${DateFormat('dd MMM').format(expectedDate.toDate())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue
                                ? Colors.red
                                : Colors.grey.shade500,
                            fontWeight: isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
