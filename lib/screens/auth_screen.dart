import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/config/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;
  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (!isValid) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _userEmail.trim(),
          password: _userPassword.trim(),
        );
        _showSuccess('Welcome back!');
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _userEmail.trim(),
          password: _userPassword.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _userName.trim(),
          'email': _userEmail.trim(),
          'online': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        _showSuccess('Account created successfully!');
      }
    } on FirebaseAuthException catch (err) {
      var message = 'An error occurred, please check your credentials!';
      if (err.message != null) {
        message = err.message!;
      }
      _showError(message);
    } catch (err) {
      _showError('An error occurred. Please try again later.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.primaryGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // App Logo and Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ChatApp',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome back!' : 'Create your account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Auth Form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                        boxShadow: AppTheme.mediumShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_isLogin) ...[
                              TextFormField(
                                key: const ValueKey('username'),
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter a username' : null,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                  ),
                                ),
                                onSaved: (value) => _userName = value!,
                              ),
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              key: const ValueKey('email'),
                              validator: (value) =>
                                  !value!.contains('@') ? 'Invalid email' : null,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                ),
                              ),
                              onSaved: (value) => _userEmail = value!,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              key: const ValueKey('password'),
                              validator: (value) => value!.length < 7
                                  ? 'Password must be at least 7 characters'
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                ),
                              ),
                              obscureText: true,
                              onSaved: (value) => _userPassword = value!,
                            ),
                            const SizedBox(height: 32),
                            
                            // Submit Button
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppTheme.primaryGradient,
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                  onTap: _isLoading ? null : _trySubmit,
                                  child: Center(
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                        : Text(
                                            _isLogin ? 'Sign In' : 'Create Account',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Toggle Auth Mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? "Don't have an account? "
                                      : "Already have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isLogin = !_isLogin);
                                  },
                                  child: Text(
                                    _isLogin ? 'Sign Up' : 'Sign In',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Connect with friends and family',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}