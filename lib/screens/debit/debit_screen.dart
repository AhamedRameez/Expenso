// lib/screens/debit_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_debit_screen.dart';
import 'debit_detail_screen.dart';

class DebitScreen extends StatefulWidget {
  const DebitScreen({super.key});

  @override
  State<DebitScreen> createState() => _DebitScreenState();
}

class _DebitScreenState extends State<DebitScreen> {
  List<Map<String, dynamic>> _debits = [];
  List<Map<String, dynamic>> _filteredDebits = [];
  double _totalToPay = 0.0;
  int _pendingCount = 0;
  int _overdueCount = 0;
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  String? _currentUserId;

  // 🎨 New color scheme - Teal & Coral
  static const Color primaryColor = Color(0xFF166534); // Teal
  static const Color accentColor = Color(0xFFF97316); // Orange/Coral
  static const Color surfaceColor = Color(0xFFF0FDFA); // Light teal bg

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadDebits();
  }

  Future<void> _loadDebits() async {
    if (_currentUserId == null) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ExpensoUsers')
          .doc(_currentUserId)
          .collection('debits')
          .orderBy('dateBorrowed', descending: true)
          .get();

      final debits = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      _applyFilter(debits);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(List<Map<String, dynamic>> debits) {
    double total = 0;
    int pending = 0;
    int overdue = 0;
    final now = DateTime.now();

    List<Map<String, dynamic>> filtered = debits;
    if (_selectedType != 'All') {
      filtered = debits.where((d) => d['debitType'] == _selectedType).toList();
    }
    if (_selectedFilter == 'Pending') {
      filtered = filtered.where((d) => d['status'] == 'pending').toList();
    } else if (_selectedFilter == 'Paid') {
      filtered = filtered.where((d) => d['status'] == 'paid').toList();
    } else if (_selectedFilter == 'Overdue') {
      filtered = filtered.where((d) {
        if (d['status'] == 'paid') return false;
        if (d['dueDate'] == null) return false;
        return (d['dueDate'] as Timestamp).toDate().isBefore(now);
      }).toList();
    }

    for (var d in debits) {
      final amount = (d['amount'] as num?)?.toDouble() ?? 0;
      final paid = (d['paidAmount'] as num?)?.toDouble() ?? 0;
      if (d['status'] != 'paid') {
        total += (amount - paid);
        pending++;
      }
      if (d['status'] != 'paid' && d['dueDate'] != null) {
        if ((d['dueDate'] as Timestamp).toDate().isBefore(now)) overdue++;
      }
    }

    if (mounted) {
      setState(() {
        _debits = debits;
        _filteredDebits = filtered;
        _totalToPay = total;
        _pendingCount = pending;
        _overdueCount = overdue;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToDetail(Map<String, dynamic> debit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DebitDetailScreen(debit: debit)),
    );
    _loadDebits();
  }

  Future<void> _navigateToAddDebit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDebitScreen()),
    );
    if (result == true) _loadDebits();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Money I Owe',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddDebit,
        backgroundColor: primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // 🎨 Compact Hero Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF166534), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF166534).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left: Icon + Label
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Center: Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total to Pay',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormat.format(_totalToPay),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Badges
                      Column(
                        children: [
                          _heroBadge('$_pendingCount Pending', accentColor),
                          const SizedBox(height: 4),
                          _heroBadge(
                            '$_overdueCount Overdue',
                            Colors.red.shade300,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 🎨 Type Selector - Pill Style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildPill('All', '📋')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPill('Personal', '👤')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPill('Business', '💼')),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('All', Icons.list_alt),
                      _buildFilterChip('Pending', Icons.hourglass_empty),
                      _buildFilterChip('Paid', Icons.check_circle),
                      _buildFilterChip('Overdue', Icons.warning_amber),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Debits List
                Expanded(
                  child: _filteredDebits.isEmpty
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
                                'No debits found',
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
                          itemCount: _filteredDebits.length,
                          itemBuilder: (context, index) => _buildDebitCard(
                            _filteredDebits[index],
                            currencyFormat,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // 🎨 Hero Badge
  Widget _heroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // 🎨 Pill Type Selector
  Widget _buildPill(String type, String emoji) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        _applyFilter(_debits);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 Filter Chip
  Widget _buildFilterChip(String filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    Color chipColor;
    if (filter == 'Paid')
      chipColor = const Color(0xFF10B981);
    else if (filter == 'Overdue')
      chipColor = const Color(0xFFEF4444);
    else if (filter == 'Pending')
      chipColor = accentColor;
    else
      chipColor = primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = filter);
          _applyFilter(_debits);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 6),
              Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
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

  // 🎨 Debit Card
  Widget _buildDebitCard(Map<String, dynamic> debit, NumberFormat cf) {
    final name = debit['personName'] as String? ?? 'Unknown';
    final amount = (debit['amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (debit['paidAmount'] as num?)?.toDouble() ?? 0;
    final status = debit['status'] as String? ?? 'pending';
    final debitType = debit['debitType'] as String? ?? 'Personal';
    final dateBorrowed = debit['dateBorrowed'] as Timestamp?;
    final dueDate = debit['dueDate'] as Timestamp?;
    final isOverdue =
        status != 'paid' &&
        dueDate != null &&
        dueDate.toDate().isBefore(DateTime.now());

    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (status == 'paid') {
      statusColor = const Color(0xFF10B981);
      statusText = 'Paid';
      statusIcon = Icons.check_circle;
    } else if (status == 'partial') {
      statusColor = accentColor;
      statusText = 'Partial';
      statusIcon = Icons.hourglass_top;
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Overdue';
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Pending';
      statusIcon = Icons.schedule;
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(debit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue ? Colors.red.shade100 : Colors.grey.shade100,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: debitType == 'Business'
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: debitType == 'Business'
                            ? const Color(0xFF6366F1)
                            : accentColor,
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
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: debitType == 'Business'
                                  ? const Color(0xFF6366F1).withOpacity(0.1)
                                  : accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              debitType == 'Business' ? '💼 Biz' : '👤 Per',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: debitType == 'Business'
                                    ? const Color(0xFF6366F1)
                                    : accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cf.format(amount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status + Progress
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: amount > 0 ? paidAmount / amount : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: statusColor,
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  dateBorrowed != null
                      ? DateFormat('dd MMM yy').format(dateBorrowed.toDate())
                      : '-',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (dueDate != null) ...[
                  Icon(
                    Icons.event,
                    size: 12,
                    color: isOverdue ? Colors.red : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${DateFormat('dd MMM').format(dueDate.toDate())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? Colors.red : Colors.grey.shade500,
                      fontWeight: isOverdue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
