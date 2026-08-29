// lib/screens/splash_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'user_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      print('🔍 SplashScreen - Current user: ${user?.email ?? "No user"}');

      if (user != null) {
        final firestore = FirebaseFirestore.instance;

        // Check ExpensoUsers collection
        final expensoUserDoc = await firestore
            .collection('ExpensoUsers')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (expensoUserDoc.exists) {
          final userData = expensoUserDoc.data();
          if (userData != null && userData['isActive'] == true) {
            print('✅ User verified, navigating to Dashboard');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserDashboard()),
              );
            }
          } else {
            print('⚠️ Account inactive, signing out');
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          }
        } else {
          print('⚠️ User document not found, signing out');
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } else {
        print('ℹ️ No user logged in, navigating to Login');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ SplashScreen error: $e');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserDashboard()),
        );
      } else if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Splash Image
            Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                        const Color(0xFFEC4899),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Colorful Loading Rings
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(child: _buildColorfulRings()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorfulRings() {
    final List<Color> ringColors = [
      const Color(0xFF6366F1), // Outer ring
      const Color(0xFF8B5CF6), // Middle ring
      const Color(0xFFEC4899), // Inner ring
    ];

    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * 3.14159,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ringColors[0]),
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
          ),

          // Middle Ring (rotates opposite direction)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_animationController.value * 2 * 3.14159,
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ringColors[1]),
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
          ),

          // Inner Ring
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 3 * 3.14159,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ringColors[2]),
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
          ),

          // Center Dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
