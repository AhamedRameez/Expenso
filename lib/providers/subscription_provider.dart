// lib/providers/subscription_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SubscriptionModel? _subscription;
  bool _isLoading = true;
  bool _hasAccess = false;
  int? _trialDaysRemaining;

  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  bool get hasAccess => _hasAccess;
  int? get trialDaysRemaining => _trialDaysRemaining;
  bool get isTrialActive => _subscription?.isTrial ?? false;
  bool get isPremium => _subscription?.isPremium ?? false;

  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      _hasAccess = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      var sub = await _service.getSubscriptionFromFirestore(user.uid);

      if (sub == null) {
        await _service.createTrialSubscription(user.uid);
        sub = await _service.getSubscriptionFromFirestore(user.uid);
      } else {
        await _service.checkAndUpdateTrialStatus(user.uid);
        sub = await _service.getSubscriptionFromFirestore(user.uid);
      }

      _subscription = sub;
      _hasAccess = sub?.hasAccess ?? false;
      _trialDaysRemaining = sub?.trialDaysRemaining;
    } catch (e) {
      _hasAccess = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await init();
  }
}