// lib/services/subscription_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';

import '../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TODO: Replace with your RevenueCat API key
  static const String _revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';

  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.verbose);
      await Purchases.configure(
        PurchasesConfiguration(_revenueCatApiKey)
          ..appUserID = _auth.currentUser?.uid,
      );
      debugPrint('✅ RevenueCat initialized');
    } catch (e) {
      debugPrint('❌ RevenueCat init failed: $e');
    }
  }

  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('premium');
    } catch (e) {
      return false;
    }
  }

  Future<SubscriptionModel?> getSubscriptionFromFirestore(String uid) async {
    try {
      final doc = await _firestore
          .collection('ExpensoUsers')
          .doc(uid)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists) {
        return SubscriptionModel.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createTrialSubscription(String uid) async {
    final trial = SubscriptionModel.createTrial();
    await _firestore
        .collection('ExpensoUsers')
        .doc(uid)
        .collection('subscription')
        .doc('current')
        .set(trial.toFirestore());

    await _firestore.collection('ExpensoUsers').doc(uid).update({
      'subscription.isPremium': trial.isPremium,
      'subscription.isTrial': trial.isTrial,
      'subscription.trialEndDate': Timestamp.fromDate(trial.trialEndDate!),
      'subscription.status': 'trialing',
    });
  }

  Future<void> checkAndUpdateTrialStatus(String uid) async {
    final subscription = await getSubscriptionFromFirestore(uid);
    if (subscription == null || !subscription.isTrial) return;

    if (subscription.isTrialExpired) {
      await _firestore
          .collection('ExpensoUsers')
          .doc(uid)
          .collection('subscription')
          .doc('current')
          .update({'isPremium': false, 'status': 'expired'});

      await _firestore.collection('ExpensoUsers').doc(uid).update({
        'subscription.isPremium': false,
        'subscription.status': 'expired',
      });
    }
  }

  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  Future<void> purchasePackage(Package package) async {
    await Purchases.purchasePackage(package);
  }

  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
}
