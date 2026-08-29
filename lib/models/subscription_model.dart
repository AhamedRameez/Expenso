// lib/models/subscription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus { trialing, active, expired, none }

class SubscriptionModel {
  final bool isPremium;
  final bool isTrial;
  final DateTime? trialEndDate;
  final SubscriptionStatus status;
  final String? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentProvider;

  SubscriptionModel({
    required this.isPremium,
    required this.isTrial,
    this.trialEndDate,
    required this.status,
    this.plan,
    this.startDate,
    this.endDate,
    this.paymentProvider,
  });

  bool get hasAccess => isPremium || isTrial;

  int? get trialDaysRemaining {
    if (!isTrial || trialEndDate == null) return null;
    final now = DateTime.now();
    final difference = trialEndDate!.difference(now);
    return difference.inDays;
  }

  bool get isTrialExpired {
    if (!isTrial || trialEndDate == null) return false;
    return DateTime.now().isAfter(trialEndDate!);
  }

  static SubscriptionModel createTrial() {
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 10));
    return SubscriptionModel(
      isPremium: true,
      isTrial: true,
      trialEndDate: trialEnd,
      status: SubscriptionStatus.trialing,
      plan: null,
      startDate: now,
      endDate: trialEnd,
      paymentProvider: null,
    );
  }

  static SubscriptionModel createPremium({
    required String plan,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return SubscriptionModel(
      isPremium: true,
      isTrial: false,
      trialEndDate: null,
      status: SubscriptionStatus.active,
      plan: plan,
      startDate: startDate,
      endDate: endDate,
      paymentProvider: 'revenuecat',
    );
  }

  static SubscriptionModel createExpired() {
    return SubscriptionModel(
      isPremium: false,
      isTrial: false,
      trialEndDate: null,
      status: SubscriptionStatus.expired,
      plan: null,
      startDate: null,
      endDate: null,
      paymentProvider: null,
    );
  }

  factory SubscriptionModel.fromFirestore(Map<String, dynamic> data) {
    final statusMap = {
      'trialing': SubscriptionStatus.trialing,
      'active': SubscriptionStatus.active,
      'expired': SubscriptionStatus.expired,
    };

    return SubscriptionModel(
      isPremium: data['isPremium'] ?? false,
      isTrial: data['isTrial'] ?? false,
      trialEndDate: data['trialEndDate'] != null
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
      status: statusMap[data['status']] ?? SubscriptionStatus.none,
      plan: data['plan'],
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      paymentProvider: data['paymentProvider'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isPremium': isPremium,
      'isTrial': isTrial,
      'trialEndDate': trialEndDate != null
          ? Timestamp.fromDate(trialEndDate!)
          : null,
      'status': status.toString().split('.').last,
      'plan': plan,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'paymentProvider': paymentProvider,
    };
  }
}
