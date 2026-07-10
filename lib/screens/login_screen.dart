// lib/screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'user_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn(); // 👈 Check if already logged in
  }

  // 👇 Check if user is already logged in
  Future<void> _checkIfAlreadyLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      // User is already logged in, check Firestore
      final firestore = FirebaseFirestore.instance;
      final expensoUserDoc = await firestore
          .collection('ExpensoUsers')
          .doc(user.uid)
          .get();

      if (expensoUserDoc.exists && mounted) {
        final userData = expensoUserDoc.data();
        if (userData != null && userData['isActive'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboard()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Validate input fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<UserAuthService>(context, listen: false);

      // Sign in with Firebase Auth
      final User? user = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        // Check if email is verified (optional - remove if not needed)
        // if (!user.emailVerified) {
        //   setState(() {
        //     _errorMessage =
        //         'Please verify your email first. Check your inbox.';
        //     _isLoading = false;
        //   });
        //   await authService.signOut();
        //   return;
        // }

        // Verify user document exists in Firestore
        final firestore = FirebaseFirestore.instance;

        // Check in ExpensoUsers collection
        final expensoUserDoc = await firestore
            .collection('ExpensoUsers')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (expensoUserDoc.exists) {
          final userData = expensoUserDoc.data();

          // Check if account is active
          if (userData != null && userData['isActive'] == true) {
            // ✅ SUCCESS - Navigate to Dashboard
            print('✅ Login successful - Navigating to Dashboard');

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserDashboard()),
              );
            }
          } else {
            // Account exists but is not active
            setState(() {
              _errorMessage = 'Account is not activated. Please contact admin.';
              _isLoading = false;
            });
            await authService.signOut();
          }
        } else {
          // User document doesn't exist in Firestore
          setState(() {
            _errorMessage =
                'User account not found. Please contact admin to set up your account.';
            _isLoading = false;
          });
          await authService.signOut();
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset('assets/images/login.png', fit: BoxFit.cover),
          ),

          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.5)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 50,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Expenso',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Track Your Expenses Smartly',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _errorMessage = null),
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ],
                          ),
                        ),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
