// // lib/screens/backup_restore_screen.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class BackupRestoreScreen extends StatefulWidget {
//   const BackupRestoreScreen({super.key});

//   @override
//   State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
// }

// class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
//   String? _currentUserId;
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _backups = [];

//   @override
//   void initState() {
//     super.initState();
//     _currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     _loadBackups();
//   }

//   // ==================== LOAD BACKUPS ====================
//   Future<void> _loadBackups() async {
//     if (_currentUserId == null) return;

//     setState(() => _isLoading = true);

//     try {
//       final firestore = FirebaseFirestore.instance;
//       final backupsSnapshot = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('backups')
//           .orderBy('createdAt', descending: true)
//           .get();

//       final backups = backupsSnapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'id': doc.id,
//           'createdAt': data['createdAt'] as Timestamp?,
//           'transactionCount': data['transactionCount'] ?? 0,
//           'totalExpense': (data['totalExpense'] as num?)?.toDouble() ?? 0.0,
//         };
//       }).toList();

//       if (mounted) {
//         setState(() {
//           _backups = backups;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading backups: $e');
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   // ==================== CREATE BACKUP ====================
//   Future<void> _createBackup() async {
//     if (_currentUserId == null) return;

//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Row(
//           children: [
//             Icon(Icons.backup_outlined, color: Color(0xFF3498DB)),
//             SizedBox(width: 8),
//             Text('Create Backup'),
//           ],
//         ),
//         content: const Text(
//           'This will create a backup of all your transactions and settings. Continue?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF3498DB),
//             ),
//             child: const Text('Backup Now'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       _showLoading('Creating backup...');

//       final firestore = FirebaseFirestore.instance;
//       final backupId = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

//       // Backup user profile
//       final userDoc = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .get();
//       if (userDoc.exists) {
//         await firestore
//             .collection('ExpensoUsers')
//             .doc(_currentUserId)
//             .collection('backups')
//             .doc(backupId)
//             .collection('data')
//             .doc('profile')
//             .set(userDoc.data()!);
//       }

//       // Backup transactions
//       final transactions = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('transactions')
//           .get();

//       int transactionCount = 0;
//       for (var doc in transactions.docs) {
//         await firestore
//             .collection('ExpensoUsers')
//             .doc(_currentUserId)
//             .collection('backups')
//             .doc(backupId)
//             .collection('data')
//             .doc('transactions')
//             .collection('items')
//             .doc(doc.id)
//             .set(doc.data()!);
//         transactionCount++;
//       }

//       // Backup settings
//       final settingsDoc = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('settings')
//           .doc('quickCategories')
//           .get();

//       if (settingsDoc.exists) {
//         await firestore
//             .collection('ExpensoUsers')
//             .doc(_currentUserId)
//             .collection('backups')
//             .doc(backupId)
//             .collection('data')
//             .doc('settings')
//             .set(settingsDoc.data()!);
//       }

//       // Save backup metadata
//       await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('backups')
//           .doc(backupId)
//           .set({
//             'backupId': backupId,
//             'createdAt': FieldValue.serverTimestamp(),
//             'transactionCount': transactionCount,
//             'totalExpense': _getTotalFromTransactions(transactions),
//           });

//       if (mounted) {
//         Navigator.pop(context);
//         _showSuccess(
//           'Backup created successfully! $transactionCount transactions saved.',
//         );
//         _loadBackups(); // Refresh list
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context);
//         _showError('Backup failed: $e');
//       }
//     }
//   }

//   // ==================== RESTORE BACKUP ====================
//   Future<void> _restoreBackup(String backupId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Row(
//           children: [
//             Icon(Icons.warning_amber_rounded, color: Colors.orange),
//             SizedBox(width: 8),
//             Text('Confirm Restore'),
//           ],
//         ),
//         content: const Text(
//           'This will replace all current transactions with the backup data. Continue?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFFE67E22),
//             ),
//             child: const Text('Restore'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       _showLoading('Restoring data...');

//       final firestore = FirebaseFirestore.instance;

//       // Delete current transactions
//       final currentTransactions = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('transactions')
//           .get();
//       for (var doc in currentTransactions.docs) {
//         await doc.reference.delete();
//       }

//       // Restore transactions from backup
//       final backupTransactions = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('backups')
//           .doc(backupId)
//           .collection('data')
//           .doc('transactions')
//           .collection('items')
//           .get();

//       int restoredCount = 0;
//       for (var doc in backupTransactions.docs) {
//         await firestore
//             .collection('ExpensoUsers')
//             .doc(_currentUserId)
//             .collection('transactions')
//             .doc(doc.id)
//             .set(doc.data()!);
//         restoredCount++;
//       }

//       // Restore settings
//       final backupSettings = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('backups')
//           .doc(backupId)
//           .collection('data')
//           .doc('settings')
//           .get();

//       if (backupSettings.exists) {
//         await firestore
//             .collection('ExpensoUsers')
//             .doc(_currentUserId)
//             .collection('settings')
//             .doc('quickCategories')
//             .set(backupSettings.data()!);
//       }

//       if (mounted) {
//         Navigator.pop(context);
//         _showSuccess('Restore complete! $restoredCount transactions restored.');
//         _loadBackups(); // Refresh list
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context);
//         _showError('Restore failed: $e');
//       }
//     }
//   }

//   // ==================== DELETE BACKUP ====================
//   Future<void> _deleteBackup(String backupId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Row(
//           children: [
//             Icon(Icons.delete_outline, color: Colors.red),
//             SizedBox(width: 8),
//             Text('Delete Backup'),
//           ],
//         ),
//         content: const Text(
//           'Are you sure you want to delete this backup? This cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       _showLoading('Deleting backup...');

//       final firestore = FirebaseFirestore.instance;

//       // Delete backup data subcollections
//       final dataDocs = await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('backups')
//           .doc(backupId)
//           .collection('data')
//           .get();

//       for (var doc in dataDocs.docs) {
//         // Delete subcollections inside data
//         final subCollections = await doc.reference.collections().toList();
//         for (var subCol in subCollections) {
//           final subDocs = await subCol.get();
//           for (var subDoc in subDocs.docs) {
//             await subDoc.reference.delete();
//           }
//         }
//         await doc.reference.delete();
//       }

//       // Delete backup document
//       await firestore
//           .collection('ExpensoUsers')
//           .doc(_currentUserId)
//           .collection('backups')
//           .doc(backupId)
//           .delete();

//       if (mounted) {
//         Navigator.pop(context);
//         _showSuccess('Backup deleted successfully!');
//         _loadBackups(); // Refresh list
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context);
//         _showError('Delete failed: $e');
//       }
//     }
//   }

//   // ==================== HELPERS ====================
//   double _getTotalFromTransactions(QuerySnapshot transactions) {
//     double total = 0;
//     for (var doc in transactions.docs) {
//       final data = doc.data() as Map<String, dynamic>;
//       total += (data['amount'] as num?)?.toDouble() ?? 0;
//     }
//     return total;
//   }

//   void _showLoading(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white, size: 18),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(message, style: const TextStyle(fontSize: 12)),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ==================== BUILD ====================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F6FA),
//       appBar: AppBar(
//         title: const Text(
//           'Backup & Restore',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: const Color(0xFF2C3E50),
//         elevation: 0,
//         centerTitle: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Create Backup Button
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0xFF3498DB).withOpacity(0.3),
//                           blurRadius: 12,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.backup_rounded,
//                             color: Colors.white,
//                             size: 32,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         const Text(
//                           'Create New Backup',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Save all your data to the cloud',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.white.withOpacity(0.8),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           onPressed: _createBackup,
//                           icon: const Icon(Icons.cloud_upload, size: 18),
//                           label: const Text('Backup Now'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             foregroundColor: const Color(0xFF3498DB),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 24,
//                               vertical: 12,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Backup History
//                   Row(
//                     children: [
//                       Container(
//                         width: 3,
//                         height: 18,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFE67E22),
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Backup History',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${_backups.length} backups',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),

//                   if (_backups.isEmpty)
//                     Container(
//                       padding: const EdgeInsets.all(40),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Column(
//                         children: [
//                           Icon(
//                             Icons.cloud_off_outlined,
//                             size: 50,
//                             color: Colors.grey.shade300,
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             'No backups found',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Create your first backup to secure your data',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   else
//                     ..._backups.map((backup) {
//                       final createdAt = backup['createdAt'] as Timestamp?;
//                       final dateStr = createdAt != null
//                           ? DateFormat(
//                               'dd MMM yyyy, hh:mm a',
//                             ).format(createdAt.toDate())
//                           : 'Unknown date';
//                       final count = backup['transactionCount'] as int;
//                       final total = backup['totalExpense'] as double;
//                       final backupId = backup['id'] as String;

//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 10),
//                         padding: const EdgeInsets.all(14),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.05),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: const Color(
//                                       0xFFE67E22,
//                                     ).withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: const Icon(
//                                     Icons.cloud_done,
//                                     color: Color(0xFFE67E22),
//                                     size: 20,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         dateStr,
//                                         style: const TextStyle(
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.w600,
//                                           color: Color(0xFF1E293B),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 2),
//                                       Text(
//                                         '$count transactions • ₹${NumberFormat('#,###').format(total)}',
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           color: Color(0xFF64748B),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: OutlinedButton.icon(
//                                     onPressed: () => _restoreBackup(backupId),
//                                     icon: const Icon(Icons.restore, size: 16),
//                                     label: const Text('Restore'),
//                                     style: OutlinedButton.styleFrom(
//                                       foregroundColor: const Color(0xFFE67E22),
//                                       side: const BorderSide(
//                                         color: Color(0xFFE67E22),
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 8,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 OutlinedButton.icon(
//                                   onPressed: () => _deleteBackup(backupId),
//                                   icon: const Icon(
//                                     Icons.delete_outline,
//                                     size: 16,
//                                   ),
//                                   label: const Text('Delete'),
//                                   style: OutlinedButton.styleFrom(
//                                     foregroundColor: Colors.red,
//                                     side: const BorderSide(color: Colors.red),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 8,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       );
//                     }),

//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//     );
//   }
// }
