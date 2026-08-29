// lib/widgets/subscription_checker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../screens/subcrp/paywall_screen.dart';

class SubscriptionChecker extends StatelessWidget {
  final Widget child;

  const SubscriptionChecker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }

        if (provider.hasAccess) {
          return child;
        }

        return const PaywallScreen();
      },
    );
  }
}